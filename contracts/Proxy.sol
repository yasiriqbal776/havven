pragma solidity ^0.4.23;

import "contracts/Owned.sol";
import "contracts/Proxyable.sol";


contract Proxy is Owned {
    Proxyable public target;

    event TargetUpdated(Proxyable _new_address);

    modifier onlyTarget() {
        require(Proxyable(msg.sender) == target,
                "caller is not proxy target");
        _;
    }

    constructor(address _owner)
        Owned(_owner)
        public
    {}

    function setTarget(Proxyable _target)
        external
        onlyOwner
    {
        target = _target;
        emit TargetUpdated(_target);
    }

    function pleaseEmit(bytes callData, uint numTopics,
                        bytes32 topicOne, bytes32 topicTwo,
                        bytes32 topicThree, bytes32 topicFour)
        external
        onlyTarget
    {
        uint size = callData.length;
        bytes memory _callData = callData;

        assembly {
            /* The first 32 bytes of callData contain its length (as specified by the abi). 
             * Length is assumed to be a uint256 and therefore maximum of 32 bytes
             * in length. It is also leftpadded to be a multiple of 32 bytes.
             * This means moving call_data across 32 bytes guarantees we correctly access
             * the data itself. */
            switch numTopics
            case 0 {
                log0(add(_callData, 32), size)
            } 
            case 1 {
                log1(add(_callData, 32), size, topicOne)
            }
            case 2 {
                log2(add(_callData, 32), size, topicOne, topicTwo)
            }
            case 3 {
                log3(add(_callData, 32), size, topicOne, topicTwo, topicThree)
            }
            case 4 {
                log4(add(_callData, 32), size, topicOne, topicTwo, topicThree, topicFour)
            }
        }
    }

    function()
        external
        payable
    {
        target.setMessageSender(msg.sender);
        assembly {
            /* Copy call data into free memory region. */
            let free_ptr := mload(0x40)
            calldatacopy(free_ptr, 0, calldatasize)

            /* Forward all gas, ether, and data to the target contract. */
            let result := call(gas, sload(target_slot), callvalue, free_ptr, calldatasize, 0, 0)
            returndatacopy(free_ptr, 0, returndatasize)

            /* Revert if the call failed, otherwise return the result. */
            if iszero(result) { revert(free_ptr, calldatasize) }
            return(free_ptr, returndatasize)
        }
    }
}
