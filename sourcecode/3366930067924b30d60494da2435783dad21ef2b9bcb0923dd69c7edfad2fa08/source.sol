/**
 *Submitted for verification at Etherscan.io on 2019-04-02
*/

pragma solidity ^0.5.0;

contract Enum {
    enum Operation {
        Call,
        DelegateCall,
        Create
    }
}

contract EtherPaymentFallback {

    /// @dev Fallback function accepts Ether transactions.
    function ()
        external
        payable
    {

    }
}

contract Executor is EtherPaymentFallback {

    event ContractCreation(address newContract);

    function execute(address to, uint256 value, bytes memory data, Enum.Operation operation, uint256 txGas)
        internal
        returns (bool success)
    {
        if (operation == Enum.Operation.Call)
            success = executeCall(to, value, data, txGas);
        else if (operation == Enum.Operation.DelegateCall)
            success = executeDelegateCall(to, data, txGas);
        else {
            address newContract = executeCreate(data);
            success = newContract != address(0);
            emit ContractCreation(newContract);
        }
    }

    function executeCall(address to, uint256 value, bytes memory data, uint256 txGas)
        internal
        returns (bool success)
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function executeDelegateCall(address to, bytes memory data, uint256 txGas)
        internal
        returns (bool success)
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function executeCreate(bytes memory data)
        internal
        returns (address newContract)
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            newContract := create(0, add(data, 0x20), mload(data))
        }
    }
}

contract SecuredTokenTransfer {

    /// @dev Transfers a token and returns if it was a success
    /// @param token Token that should be transferred
    /// @param receiver Receiver to whom the token should be transferred
    /// @param amount The amount of tokens that should be transferred
    function transferToken (
        address token, 
        address receiver,
        uint256 amount
    )
        internal
        returns (bool transferred)
    {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", receiver, amount);
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let success := call(sub(gas, 10000), token, 0, add(data, 0x20), mload(data), 0, 0)
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize)
            switch returndatasize 
            case 0 { transferred := success }
            case 0x20 { transferred := iszero(or(iszero(success), iszero(mload(ptr)))) }
            default { transferred := 0 }
        }
    }
}

contract SelfAuthorized {
    modifier authorized() {
        require(msg.sender == address(this), "Method can only be called from this contract");
        _;
    }
}

contract ModuleManager is SelfAuthorized, Executor {

    event EnabledModule(Module module);
    event DisabledModule(Module module);

    address public constant SENTINEL_MODULES = address(0x1);

    mapping (address => address) internal modules;
    
    function setupModules(address to, bytes memory data)
        internal
    {
        require(modules[SENTINEL_MODULES] == address(0), "Modules have already been initialized");
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
        if (to != address(0))
            // Setup has to complete successfully or transaction fails.
            require(executeDelegateCall(to, data, gasleft()), "Could not finish initialization");
    }

    /// @dev Allows to add a module to the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @param module Module to be whitelisted.
    function enableModule(Module module)
        public
        authorized
    {
        // Module address cannot be null or sentinel.
        require(address(module) != address(0) && address(module) != SENTINEL_MODULES, "Invalid module address provided");
        // Module cannot be added twice.
        require(modules[address(module)] == address(0), "Module has already been added");
        modules[address(module)] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = address(module);
        emit EnabledModule(module);
    }

    /// @dev Allows to remove a module from the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @param prevModule Module that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(Module prevModule, Module module)
        public
        authorized
    {
        // Validate module address and check that it corresponds to module index.
        require(address(module) != address(0) && address(module) != SENTINEL_MODULES, "Invalid module address provided");
        require(modules[address(prevModule)] == address(module), "Invalid prevModule, module pair provided");
        modules[address(prevModule)] = modules[address(module)];
        modules[address(module)] = address(0);
        emit DisabledModule(module);
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes memory data, Enum.Operation operation)
        public
        returns (bool success)
    {
        // Only whitelisted modules are allowed.
        require(modules[msg.sender] != address(0), "Method can only be called from an enabled module");
        // Execute transaction without further confirmations.
        success = execute(to, value, data, operation, gasleft());
    }

    /// @dev Returns array of modules.
    /// @return Array of modules.
    function getModules()
        public
        view
        returns (address[] memory)
    {
        // Calculate module count
        uint256 moduleCount = 0;
        address currentModule = modules[SENTINEL_MODULES];
        while(currentModule != SENTINEL_MODULES) {
            currentModule = modules[currentModule];
            moduleCount ++;
        }
        address[] memory array = new address[](moduleCount);

        // populate return array
        moduleCount = 0;
        currentModule = modules[SENTINEL_MODULES];
        while(currentModule != SENTINEL_MODULES) {
            array[moduleCount] = currentModule;
            currentModule = modules[currentModule];
            moduleCount ++;
        }
        return array;
    }
}

contract OwnerManager is SelfAuthorized {

    event AddedOwner(address owner);
    event RemovedOwner(address owner);
    event ChangedThreshold(uint256 threshold);

    address public constant SENTINEL_OWNERS = address(0x1);

    mapping(address => address) internal owners;
    uint256 ownerCount;
    uint256 internal threshold;

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    function setupOwners(address[] memory _owners, uint256 _threshold)
        internal
    {
        // Threshold can only be 0 at initialization.
        // Check ensures that setup function can only be called once.
        require(threshold == 0, "Owners have already been setup");
        // Validate that threshold is smaller than number of added owners.
        require(_threshold <= _owners.length, "Threshold cannot exceed owner count");
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "Threshold needs to be greater than 0");
        // Initializing Safe owners.
        address currentOwner = SENTINEL_OWNERS;
        for (uint256 i = 0; i < _owners.length; i++) {
            // Owner address cannot be null.
            address owner = _owners[i];
            require(owner != address(0) && owner != SENTINEL_OWNERS, "Invalid owner address provided");
            // No duplicate owners allowed.
            require(owners[owner] == address(0), "Duplicate owner address provided");
            owners[currentOwner] = owner;
            currentOwner = owner;
        }
        owners[currentOwner] = SENTINEL_OWNERS;
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    /// @dev Allows to add a new owner to the Safe and update the threshold at the same time.
    ///      This can only be done via a Safe transaction.
    /// @param owner New owner address.
    /// @param _threshold New threshold.
    function addOwnerWithThreshold(address owner, uint256 _threshold)
        public
        authorized
    {
        // Owner address cannot be null.
        require(owner != address(0) && owner != SENTINEL_OWNERS, "Invalid owner address provided");
        // No duplicate owners allowed.
        require(owners[owner] == address(0), "Address is already an owner");
        owners[owner] = owners[SENTINEL_OWNERS];
        owners[SENTINEL_OWNERS] = owner;
        ownerCount++;
        emit AddedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold)
            changeThreshold(_threshold);
    }

    /// @dev Allows to remove an owner from the Safe and update the threshold at the same time.
    ///      This can only be done via a Safe transaction.
    /// @param prevOwner Owner that pointed to the owner to be removed in the linked list
    /// @param owner Owner address to be removed.
    /// @param _threshold New threshold.
    function removeOwner(address prevOwner, address owner, uint256 _threshold)
        public
        authorized
    {
        // Only allow to remove an owner, if threshold can still be reached.
        require(ownerCount - 1 >= _threshold, "New owner count needs to be larger than new threshold");
        // Validate owner address and check that it corresponds to owner index.
        require(owner != address(0) && owner != SENTINEL_OWNERS, "Invalid owner address provided");
        require(owners[prevOwner] == owner, "Invalid prevOwner, owner pair provided");
        owners[prevOwner] = owners[owner];
        owners[owner] = address(0);
        ownerCount--;
        emit RemovedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold)
            changeThreshold(_threshold);
    }

    /// @dev Allows to swap/replace an owner from the Safe with another address.
    ///      This can only be done via a Safe transaction.
    /// @param prevOwner Owner that pointed to the owner to be replaced in the linked list
    /// @param oldOwner Owner address to be replaced.
    /// @param newOwner New owner address.
    function swapOwner(address prevOwner, address oldOwner, address newOwner)
        public
        authorized
    {
        // Owner address cannot be null.
        require(newOwner != address(0) && newOwner != SENTINEL_OWNERS, "Invalid owner address provided");
        // No duplicate owners allowed.
        require(owners[newOwner] == address(0), "Address is already an owner");
        // Validate oldOwner address and check that it corresponds to owner index.
        require(oldOwner != address(0) && oldOwner != SENTINEL_OWNERS, "Invalid owner address provided");
        require(owners[prevOwner] == oldOwner, "Invalid prevOwner, owner pair provided");
        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = address(0);
        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }

    /// @dev Allows to update the number of required confirmations by Safe owners.
    ///      This can only be done via a Safe transaction.
    /// @param _threshold New threshold.
    function changeThreshold(uint256 _threshold)
        public
        authorized
    {
        // Validate that threshold is smaller than number of owners.
        require(_threshold <= ownerCount, "Threshold cannot exceed owner count");
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "Threshold needs to be greater than 0");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    function getThreshold()
        public
        view
        returns (uint256)
    {
        return threshold;
    }

    function isOwner(address owner)
        public
        view
        returns (bool)
    {
        return owners[owner] != address(0);
    }

    /// @dev Returns array of owners.
    /// @return Array of Safe owners.
    function getOwners()
        public
        view
        returns (address[] memory)
    {
        address[] memory array = new address[](ownerCount);

        // populate return array
        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];
        while(currentOwner != SENTINEL_OWNERS) {
            array[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index ++;
        }
        return array;
    }
}

contract BaseSafe is ModuleManager, OwnerManager {

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    /// @param to Contract address for optional delegate call.
    /// @param data Data payload for optional delegate call.
    function setupSafe(address[] memory _owners, uint256 _threshold, address to, bytes memory data)
        internal
    {
        setupOwners(_owners, _threshold);
        // As setupOwners can only be called if the contract has not been initialized we don't need a check for setupModules
        setupModules(to, data);
    }
}

contract MasterCopy is SelfAuthorized {
  // masterCopy always needs to be first declared variable, to ensure that it is at the same location as in the Proxy contract.
  // It should also always be ensured that the address is stored alone (uses a full word)
    address masterCopy;

  /// @dev Allows to upgrade the contract. This can only be done via a Safe transaction.
  /// @param _masterCopy New contract address.
    function changeMasterCopy(address _masterCopy)
        public
        authorized
    {
        // Master copy address cannot be null.
        require(_masterCopy != address(0), "Invalid master copy address provided");
        masterCopy = _masterCopy;
    }
}

contract Module is MasterCopy {

    ModuleManager public manager;

    modifier authorized() {
        require(msg.sender == address(manager), "Method can only be called from manager");
        _;
    }

    function setManager()
        internal
    {
        // manager can only be 0 at initalization of contract.
        // Check ensures that setup function can only be called once.
        require(address(manager) == address(0), "Manager has already been set");
        manager = ModuleManager(msg.sender);
    }
}

contract SignatureDecoder {
    
    /// @dev Recovers address who signed the message 
    /// @param messageHash operation ethereum signed message hash
    /// @param messageSignature message `txHash` signature
    /// @param pos which signature to read
    function recoverKey (
        bytes32 messageHash, 
        bytes memory messageSignature,
        uint256 pos
    )
        internal
        pure
        returns (address) 
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = signatureSplit(messageSignature, pos);
        return ecrecover(messageHash, v, r, s);
    }

    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`
    /// @param pos which signature to read
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract ISignatureValidator {
    /**
    * @dev Should return whether the signature provided is valid for the provided data
    * @param _data Arbitrary length data signed on the behalf of address(this)
    * @param _signature Signature byte array associated with _data
    *
    * MUST return a bool upon valid or invalid signature with corresponding _data
    * MUST take (bytes, bytes) as arguments
    */ 
    function isValidSignature(
        bytes calldata _data, 
        bytes calldata _signature)
        external
        returns (bool isValid) {}
}

contract GnosisSafe is MasterCopy, BaseSafe, SignatureDecoder, SecuredTokenTransfer, ISignatureValidator {

    using SafeMath for uint256;

    string public constant NAME = "Gnosis Safe";
    string public constant VERSION = "0.1.0";

    //keccak256(
    //    "EIP712Domain(address verifyingContract)"
    //);
    bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH = 0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749;

    //keccak256(
    //    "SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 dataGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
    //);
    bytes32 public constant SAFE_TX_TYPEHASH = 0x14d461bc7412367e924637b363c7bf29b8f47e2f84869f4426e5633d8af47b20;

    //keccak256(
    //    "SafeMessage(bytes message)"
    //);
    bytes32 public constant SAFE_MSG_TYPEHASH = 0x60b3cbf8b4a223d68d641b3b6ddf9a298e7f33710cf3d3a9d1146b5a6150fbca;

    event ExecutionFailed(bytes32 txHash);

    uint256 public nonce;
    bytes32 public domainSeparator;
    // Mapping to keep track of all message hashes that have been approve by ALL REQUIRED owners
    mapping(bytes32 => uint256) public signedMessages;
    // Mapping to keep track of all hashes (message or transaction) that have been approve by ANY owners
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    /// @param to Contract address for optional delegate call.
    /// @param data Data payload for optional delegate call.
    function setup(address[] calldata _owners, uint256 _threshold, address to, bytes calldata data)
        external
    {
        require(domainSeparator == 0, "Domain Separator already set!");
        domainSeparator = keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, this));
        setupSafe(_owners, _threshold, to, data);
    }

    /// @dev Allows to execute a Safe transaction confirmed by required number of owners and then pays the account that submitted the transaction.
    ///      Note: The fees are always transfered, even if the user transaction fails.
    /// @param to Destination address of Safe transaction.
    /// @param value Ether value of Safe transaction.
    /// @param data Data payload of Safe transaction.
    /// @param operation Operation type of Safe transaction.
    /// @param safeTxGas Gas that should be used for the Safe transaction.
    /// @param dataGas Gas costs for data used to trigger the safe transaction and to pay the payment transfer
    /// @param gasPrice Gas price that should be used for the payment calculation.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param signatures Packed signature data ({bytes32 r}{bytes32 s}{uint8 v})
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 dataGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes calldata signatures
    )
        external
        returns (bool success)
    {
        uint256 startGas = gasleft();
        bytes memory txHashData = encodeTransactionData(
            to, value, data, operation, // Transaction info
            safeTxGas, dataGas, gasPrice, gasToken, refundReceiver, // Payment info
            nonce
        );
        require(checkSignatures(keccak256(txHashData), txHashData, signatures, true), "Invalid signatures provided");
        // Increase nonce and execute transaction.
        nonce++;
        require(gasleft() >= safeTxGas, "Not enough gas to execute safe transaction");
        // If no safeTxGas has been set and the gasPrice is 0 we assume that all available gas can be used
        success = execute(to, value, data, operation, safeTxGas == 0 && gasPrice == 0 ? gasleft() : safeTxGas);
        if (!success) {
            emit ExecutionFailed(keccak256(txHashData));
        }

        // We transfer the calculated tx costs to the tx.origin to avoid sending it to intermediate contracts that have made calls
        if (gasPrice > 0) {
            handlePayment(startGas, dataGas, gasPrice, gasToken, refundReceiver);
        }
    }

    function handlePayment(
        uint256 startGas,
        uint256 dataGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver
    )
        private
    {
        uint256 amount = startGas.sub(gasleft()).add(dataGas).mul(gasPrice);
        // solium-disable-next-line security/no-tx-origin
        address payable receiver = refundReceiver == address(0) ? tx.origin : refundReceiver;
        if (gasToken == address(0)) {
            // solium-disable-next-line security/no-send
            require(receiver.send(amount), "Could not pay gas costs with ether");
        } else {
            require(transferToken(gasToken, receiver, amount), "Could not pay gas costs with token");
        }
    }

    /**
    * @dev Should return whether the signature provided is valid for the provided data, hash
    * @param dataHash Hash of the data (could be either a message hash or transaction hash)
    * @param data That should be signed (this is passed to an external validator contract)
    * @param signatures Signature data that should be verified. Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
    * @param consumeHash Indicates that in case of an approved hash the storage can be freed to save gas
    * @return a bool upon valid or invalid signature with corresponding _data
    */
    function checkSignatures(bytes32 dataHash, bytes memory data, bytes memory signatures, bool consumeHash)
        internal
        returns (bool)
    {
        // Check that the provided signature data is not too short
        if (signatures.length < threshold * 65) {
            return false;
        }
        // There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            // If v is 0 then it is a contract signature
            if (v == 0) {
                // When handling contract signatures the address of the contract is encoded into r
                currentOwner = address(uint256(r));
                bytes memory contractSignature;
                // solium-disable-next-line security/no-inline-assembly
                assembly {
                    // The signature data for contract signatures is appended to the concatenated signatures and the offset is stored in s
                    contractSignature := add(add(signatures, s), 0x20)
                }
                if (!ISignatureValidator(currentOwner).isValidSignature(data, contractSignature)) {
                    return false;
                }
            // If v is 1 then it is an approved hash
            } else if (v == 1) {
                // When handling approved hashes the address of the approver is encoded into r
                currentOwner = address(uint256(r));
                // Hashes are automatically approved by the sender of the message or when they have been pre-approved via a separate transaction
                if (msg.sender != currentOwner && approvedHashes[currentOwner][dataHash] == 0) {
                    return false;
                }
                // Hash has been marked for consumption. If this hash was pre-approved free storage
                if (consumeHash && msg.sender != currentOwner) {
                    approvedHashes[currentOwner][dataHash] = 0;
                }
            } else {
                // Use ecrecover with the messageHash for EOA signatures
                currentOwner = ecrecover(dataHash, v, r, s);
            }
            if (currentOwner <= lastOwner || owners[currentOwner] == address(0)) {
                return false;
            }
            lastOwner = currentOwner;
        }
        return true;
    }

    /// @dev Allows to estimate a Safe transaction.
    ///      This method is only meant for estimation purpose, therfore two different protection mechanism against execution in a transaction have been made:
    ///      1.) The method can only be called from the safe itself
    ///      2.) The response is returned with a revert
    ///      When estimating set `from` to the address of the safe.
    ///      Since the `estimateGas` function includes refunds, call this method to get an estimated of the costs that are deducted from the safe with `execTransaction`
    /// @param to Destination address of Safe transaction.
    /// @param value Ether value of Safe transaction.
    /// @param data Data payload of Safe transaction.
    /// @param operation Operation type of Safe transaction.
    /// @return Estimate without refunds and overhead fees (base transaction and payload data gas costs).
    function requiredTxGas(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        authorized
        returns (uint256)
    {
        uint256 startGas = gasleft();
        // We don't provide an error message here, as we use it to return the estimate
        // solium-disable-next-line error-reason
        require(execute(to, value, data, operation, gasleft()));
        uint256 requiredGas = startGas - gasleft();
        // Convert response to string and return via error message
        revert(string(abi.encodePacked(requiredGas)));
    }

    /**
    * @dev Marks a hash as approved. This can be used to validate a hash that is used by a signature.
    * @param hashToApprove The hash that should be marked as approved for signatures that are verified by this contract.
    */
    function approveHash(bytes32 hashToApprove)
        external
    {
        require(owners[msg.sender] != address(0), "Only owners can approve a hash");
        approvedHashes[msg.sender][hashToApprove] = 1;
    }

    /**
    * @dev Marks a message as signed
    * @param _data Arbitrary length data that should be marked as signed on the behalf of address(this)
    */ 
    function signMessage(bytes calldata _data) 
        external
        authorized
    {
        signedMessages[getMessageHash(_data)] = 1;
    }

    /**
    * @dev Should return whether the signature provided is valid for the provided data
    * @param _data Arbitrary length data signed on the behalf of address(this)
    * @param _signature Signature byte array associated with _data
    * @return a bool upon valid or invalid signature with corresponding _data
    */ 
    function isValidSignature(bytes calldata _data, bytes calldata _signature)
        external
        returns (bool isValid)
    {
        bytes32 messageHash = getMessageHash(_data);
        if (_signature.length == 0) {
            isValid = signedMessages[messageHash] != 0;
        } else {
            // consumeHash needs to be false, as the state should not be changed
            isValid = checkSignatures(messageHash, _data, _signature, false);
        }
    }

    /// @dev Returns hash of a message that can be signed by owners.
    /// @param message Message that should be hashed
    /// @return Message hash.
    function getMessageHash(
        bytes memory message
    )
        public
        view
        returns (bytes32)
    {
        bytes32 safeMessageHash = keccak256(
            abi.encode(SAFE_MSG_TYPEHASH, keccak256(message))
        );
        return keccak256(
            abi.encodePacked(byte(0x19), byte(0x01), domainSeparator, safeMessageHash)
        );
    }

    /// @dev Returns the bytes that are hashed to be signed by owners.
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param data Data payload.
    /// @param operation Operation type.
    /// @param safeTxGas Fas that should be used for the safe transaction.
    /// @param dataGas Gas costs for data used to trigger the safe transaction.
    /// @param gasPrice Maximum gas price that should be used for this transaction.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param _nonce Transaction nonce.
    /// @return Transaction hash bytes.
    function encodeTransactionData(
        address to, 
        uint256 value, 
        bytes memory data, 
        Enum.Operation operation, 
        uint256 safeTxGas, 
        uint256 dataGas, 
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    )
        public
        view
        returns (bytes memory)
    {
        bytes32 safeTxHash = keccak256(
            abi.encode(SAFE_TX_TYPEHASH, to, value, keccak256(data), operation, safeTxGas, dataGas, gasPrice, gasToken, refundReceiver, _nonce)
        );
        return abi.encodePacked(byte(0x19), byte(0x01), domainSeparator, safeTxHash);
    }

    /// @dev Returns hash to be signed by owners.
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param data Data payload.
    /// @param operation Operation type.
    /// @param safeTxGas Fas that should be used for the safe transaction.
    /// @param dataGas Gas costs for data used to trigger the safe transaction.
    /// @param gasPrice Maximum gas price that should be used for this transaction.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param _nonce Transaction nonce.
    /// @return Transaction hash.
    function getTransactionHash(
        address to, 
        uint256 value, 
        bytes memory data, 
        Enum.Operation operation, 
        uint256 safeTxGas, 
        uint256 dataGas, 
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(encodeTransactionData(to, value, data, operation, safeTxGas, dataGas, gasPrice, gasToken, refundReceiver, _nonce));
    }
}

/// @title DutchX Base Module - Expose a set of methods to enable a Safe to interact with a DX
/// @author Denis Granha - <[email protected]>
contract DutchXBaseModule is Module {

    address public dutchXAddress;
    // isWhitelistedToken mapping maps destination address to boolean.
    mapping (address => bool) public isWhitelistedToken;
    mapping (address => bool) public isOperator;

    // helper variables used by the CLI
    address[] public whitelistedTokens; 
    address[] public whitelistedOperators;

    /// @dev Setup function sets initial storage of contract.
    /// @param dx DutchX Proxy Address.
    /// @param tokens List of whitelisted tokens.
    /// @param operators List of addresses that can operate the module.
    /// @param _manager Address of the manager, the safe contract.
    function setup(address dx, address[] memory tokens, address[] memory operators, address payable _manager)
        public
    {
        require(address(manager) == address(0), "Manager has already been set");
        if (_manager == address(0)){
            manager = ModuleManager(msg.sender);
        }
        else{
            manager = ModuleManager(_manager);
        }

        dutchXAddress = dx;

        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            require(token != address(0), "Invalid token provided");
            isWhitelistedToken[token] = true;
        }

        whitelistedTokens = tokens;

        for (uint256 i = 0; i < operators.length; i++) {
            address operator = operators[i];
            require(operator != address(0), "Invalid operator address provided");
            isOperator[operator] = true;
        }

        whitelistedOperators = operators;
    }

    /// @dev Allows to add token to whitelist. This can only be done via a Safe transaction.
    /// @param token ERC20 token address.
    function addToWhitelist(address token)
        public
        authorized
    {
        require(token != address(0), "Invalid token provided");
        require(!isWhitelistedToken[token], "Token is already whitelisted");
        isWhitelistedToken[token] = true;
        whitelistedTokens.push(token);
    }

    /// @dev Allows to remove token from whitelist. This can only be done via a Safe transaction.
    /// @param token ERC20 token address.
    function removeFromWhitelist(address token)
        public
        authorized
    {
        require(isWhitelistedToken[token], "Token is not whitelisted");
        isWhitelistedToken[token] = false;

        for (uint i = 0; i<whitelistedTokens.length - 1; i++)
            if(whitelistedTokens[i] == token){
                whitelistedTokens[i] = whitelistedTokens[whitelistedTokens.length-1];
                break;
            }
        whitelistedTokens.length -= 1;
    }

    /// @dev Allows to add operator to whitelist. This can only be done via a Safe transaction.
    /// @param operator ethereum address.
    function addOperator(address operator)
        public
        authorized
    {
        require(operator != address(0), "Invalid address provided");
        require(!isOperator[operator], "Operator is already whitelisted");
        isOperator[operator] = true;
        whitelistedOperators.push(operator);
    }

    /// @dev Allows to remove operator from whitelist. This can only be done via a Safe transaction.
    /// @param operator ethereum address.
    function removeOperator(address operator)
        public
        authorized
    {
        require(isOperator[operator], "Operator is not whitelisted");
        isOperator[operator] = false;

        for (uint i = 0; i<whitelistedOperators.length - 1; i++)
            if(whitelistedOperators[i] == operator){
                whitelistedOperators[i] = whitelistedOperators[whitelistedOperators.length-1];
                break;
            }
        whitelistedOperators.length -= 1;

    }

    /// @dev Allows to change DutchX Proxy contract address. This can only be done via a Safe transaction.
    /// @param dx New proxy contract address for DutchX.
    function changeDXProxy(address dx)
        public
        authorized
    {
        require(dx != address(0), "Invalid address provided");
        dutchXAddress = dx;
    }

    /// @dev Abstract method. Returns if Safe transaction is to DutchX contract and with whitelisted tokens.
    /// @param to Dutch X address or Whitelisted token (only for approve operations for DX).
    /// @param value Not checked.
    /// @param data Allowed operations
    /// @return Returns if transaction can be executed.
    function executeWhitelisted(address to, uint256 value, bytes memory data)
        public
        returns (bool);


    /// @dev Returns list of whitelisted tokens.
    /// @return List of whitelisted tokens addresses.
    function getWhitelistedTokens()
        public
        view
        returns (address[] memory)
    {
        return whitelistedTokens;
    }

    /// @dev Returns list of whitelisted operators.
    /// @return List of whitelisted operators addresses.
    function getWhitelistedOperators()
        public
        view
        returns (address[] memory)
    {
        return whitelistedOperators;
    }
}

// @title DutchX Token Interface - Represents the allowed methods of ERC20 token contracts to be executed from the safe module DutchXModule
/// @author Denis Granha - <[email protected]>
interface DutchXTokenInterface {
	function transfer(address to, uint value) external;
    function approve(address spender, uint amount) external;
    function deposit() external payable;
    function withdraw() external;
}

// @title DutchX Interface - Represents the allowed methods to be executed from the safe module DutchXModule
/// @author Denis Granha - <[email protected]>
interface DutchXInterface {
	function deposit(address token, uint256 amount) external;
    function postSellOrder(address sellToken, address buyToken, uint256 auctionIndex, uint256 amount) external;
    function postBuyOrder(address sellToken, address buyToken, uint256 auctionIndex, uint256 amount) external;

    function claimTokensFromSeveralAuctionsAsBuyer(
        address[] calldata auctionSellTokens, 
        address[] calldata auctionBuyTokens,
        uint[] calldata auctionIndices, 
        address user
    ) external;

    function claimTokensFromSeveralAuctionsAsSeller(
        address[] calldata auctionSellTokens,
        address[] calldata auctionBuyTokens,
        uint[] calldata auctionIndices,
        address user
    ) external;

    function withdraw() external;
}

/// @title DutchX Module - Allows to execute transactions to DutchX contract for whitelisted token pairs without confirmations and deposit tokens in the DutchX.
//  differs from the Complete module in the allowed functions, it doesn't allow to perform buy operations.
/// @author Denis Granha - <[email protected]>
contract DutchXSellerModule is DutchXBaseModule {

    string public constant NAME = "DutchX Seller Module";
    string public constant VERSION = "0.0.2";

    /// @dev Returns if Safe transaction is to DutchX contract and with whitelisted tokens.
    /// @param to Dutch X address or Whitelisted token (only for approve operations for DX).
    /// @param value Not checked.
    /// @param data Allowed operations (postSellOrder, postBuyOrder, claimTokensFromSeveralAuctionsAsBuyer, claimTokensFromSeveralAuctionsAsSeller, deposit).
    /// @return Returns if transaction can be executed.
    function executeWhitelisted(address to, uint256 value, bytes memory data)
        public
        returns (bool)
    {

        // Load allowed method interfaces
        DutchXTokenInterface tokenInterface;
        DutchXInterface dxInterface;

        // Only Safe owners are allowed to execute transactions to whitelisted accounts.
        require(isOperator[msg.sender], "Method can only be called by an operator");

        // Only DutchX Proxy and Whitelisted tokens are allowed as destination
        require(to == dutchXAddress || isWhitelistedToken[to], "Destination address is not allowed");

        // Decode data
        bytes4 functionIdentifier;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            functionIdentifier := mload(add(data, 0x20))
        }

        // Only approve tokens function and deposit (in the case of WETH) is allowed against token contracts, and DutchX proxy must be the spender (for approve)
        if (functionIdentifier != tokenInterface.deposit.selector){
            require(value == 0, "Eth transactions only allowed for wrapping ETH");
        }

        // Only these functions:
        // PostSellOrder, claimTokensFromSeveralAuctionsAsBuyer, claimTokensFromSeveralAuctionsAsSeller, deposit
        // Are allowed for the Dutch X contract
        if (functionIdentifier == tokenInterface.approve.selector) {
            uint spender;
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                spender := mload(add(data, 0x24))
            }

            // TODO we need abi.decodeWithSelector
            // approve(address spender, uint256 amount) we skip the amount
            // (address spender) = abi.decode(dataParams, (address));

            require(address(spender) == dutchXAddress, "Spender must be the DutchX Contract");
        } else if (functionIdentifier == dxInterface.deposit.selector) {
            // TODO we need abi.decodeWithSelector
            // deposit(address token, uint256 amount) we skip the amount
            // (address token) = abi.decode(data, (address));

            uint depositToken;
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                depositToken := mload(add(data, 0x24))
            }
            require (isWhitelistedToken[address(depositToken)], "Only whitelisted tokens can be deposit on the DutchX");
        } else if (functionIdentifier == dxInterface.postSellOrder.selector) {
            // TODO we need abi.decodeWithSelector
            // postSellOrder(address sellToken, address buyToken, uint256 auctionIndex, uint256 amount) we skip auctionIndex and amount
            // (address sellToken, address buyToken) = abi.decode(data, (address, address));

            uint sellToken;
            uint buyToken;
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                sellToken := mload(add(data, 0x24))
                buyToken := mload(add(data, 0x44))
            }
            require (isWhitelistedToken[address(sellToken)] && isWhitelistedToken[address(buyToken)], "Only whitelisted tokens can be sold");
        } else {
            // Other functions different than claim and deposit are not allowed
            require(functionIdentifier == dxInterface.claimTokensFromSeveralAuctionsAsSeller.selector || functionIdentifier == dxInterface.claimTokensFromSeveralAuctionsAsBuyer.selector || functionIdentifier == tokenInterface.deposit.selector, "Function not allowed");
        }

        require(manager.execTransactionFromModule(to, value, data, Enum.Operation.Call), "Could not execute transaction");
    }
}