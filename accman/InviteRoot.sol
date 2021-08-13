pragma ton-solidity >=0.43.0;
pragma AbiHeader expire;
pragma AbiHeader time;
import "Invite.sol";
import "RedensLib.sol";

enum InviteType {
    Public, 
    Private,
    Self,
    Unknown
}

contract InviteRoot {

    TvmCell m_inviteImage;
    mapping(uint256 => bool) m_hashPool;
    address m_ownerAddress;

    modifier onlyOwner() {
        require(msg.pubkey() == tvm.pubkey(), 100);
        tvm.accept();
        _;
    }

    constructor(TvmCell image, address ownerAddress) public {
        require(msg.sender != address(0), 102);
        // TODO: check signature generated from ownerAddress using tvm.pubkey().
        m_inviteImage = image;
        m_ownerAddress = ownerAddress;
    }

    function addInvites(uint256[] hashes) public view onlyOwner {
        for(uint i = 0; i < hashes.length; i++) {
            if (!m_hashPool.exists(hashes[i]) ) {
                m_hashPool[hashes[i]];
            }
        }
    }

    function deleteInvite(uint256 hash) public onlyOwner {
        delete m_hashPool[hash];
    }

    //
    // Public invite API
    //

    function createPrivateInvite(string nonce, address account) public {
        require(msg.sender != address(0));
        uint256 hash = tvm.hash(nonce);
        require(m_hashPool.exists(hash), 101);
        deployInvite(account, InviteType.Private, false);
        delete m_hashPool[hash];
    }

    function createSelfInvite(address account) public view {
        require(msg.sender == m_ownerAddress, 103);
        deployInvite(account, InviteType.Self, false);
    }

    function createPublicInvite(address account) public view {
        require(msg.sender != address(0));
        deployInvite(account, InviteType.Public, false);
    }

    function destroyInvite(address account, InviteType inviteType) public view {
        require(msg.sender == m_ownerAddress, 103);
        TvmBuilder saltBuilder;
        // uint8 (invite type) + address (invite root addr).
        // types: 0 - public invite, 1 - private invite
        address root = address(this);
        saltBuilder.store(uint8(inviteType), root);

        TvmCell code = tvm.setCodeSalt(
            m_inviteImage.toSlice().loadRef(),
            saltBuilder.toCell()
        );

        address currInvite = address(tvm.hash(
            tvm.buildStateInit({ 
                code: code,
                pubkey: tvm.pubkey(),
                varInit: {account: account},
                contr: Invite
            })
        ));

        _sendDestroyInvite(currInvite);
    }

    ///////////////////////////////////////////////////////////////////////////////

    function deployInvite(address account, InviteType inviteType, bool isExternal) private view 
        returns (address) {
        TvmBuilder saltBuilder;
        // uint8 (invite type) + address (invite root addr) + root owner public key.
        // types: 0 - public invite, 1 - private invite
        saltBuilder.store(uint8(inviteType), address(this), tvm.pubkey());
        TvmCell code = tvm.setCodeSalt(
            m_inviteImage.toSlice().loadRef(),
            saltBuilder.toCell()
        );
        (uint128 value, uint16 flag) = isExternal ? (1 ton, 3) : (0, 64);
        return _sendDeployInvite(code, account, value, flag);
    }

    function _sendDeployInvite(TvmCell code, address account, uint128 value, uint16 flag) private view returns (address) {
        return new Invite {
            value: value,
            flag: flag,
            bounce: true,
            code: code,
            pubkey: RedensLib.INVITE_KEY,
            varInit: { account: account } 
        }();
    }

    function _sendDestroyInvite(address invite) private pure {
        Invite2(invite).destroy();
    }

    //
    // Get-methods
    //

    function getNonces() public view returns (mapping(uint256 => bool) nonces) {
        nonces = m_hashPool;
    }
}