pragma ton-solidity >=0.43.0;
pragma AbiHeader expire;
pragma AbiHeader time;

contract Invite {

    uint8 public version = 2;
    
    address static account;

    constructor() public {
        TvmCell code = tvm.code();
        optional(address) rootAddr = _rootAddress();
        require(rootAddr.hasValue(), 101);
        require(msg.sender == rootAddr.get(), 102);
        tvm.setPubkey(0);
    }

    
    function destroy() public {
        optional(address) rootAddr = _rootAddress();
        require(rootAddr.hasValue(), 101);
        require(msg.sender == rootAddr.get(), 102);
        selfdestruct(rootAddr.get());
    }

    function getParams() public pure 
        returns (InviteType kind, address rootAddr, uint256 ownerPubkey) {
        requuire(msg.sender == address(0));
        TvmCell code = tvm.code();
        optional(TvmCell) salt = tvm.codeSalt(code);
        if (salt.hasValue()) {
            (kind, rootAddr, ownerPubkey) = salt.get().toSlice().decode(uint8, address, uint256);
        } else {
            kind = InviteType.Unknown;
            rootAddr = address(0);
            ownerPubkey = 0;
        }
    }

    function _rootAddress() internal pure returns (optional(address)) {
        optional(address) addr;
        TvmCell code = tvm.code();
        optional(TvmCell) salt = tvm.codeSalt(code);
        if (salt.hasValue()) {
            (, address rootAddr) = salt.get().toSlice().decode(uint8, address);
            addr = rootAddr;
        }
        return addr;
    }

}