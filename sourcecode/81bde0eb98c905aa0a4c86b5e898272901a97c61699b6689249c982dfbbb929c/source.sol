/**
 *Submitted for verification at Etherscan.io on 2018-06-14
*/

pragma solidity 0.4.23;

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */

contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

contract SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint256) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal pure returns (uint256) {
    uint c = a / b;
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint256) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}


/**
 * @title Stoppable
 * @dev Base contract which allows children to implement final irreversible stop mechanism.
 */
contract Stoppable is Pausable {
  event Stop();

  bool public stopped = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not stopped.
   */
  modifier whenNotStopped() {
    require(!stopped);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is stopped.
   */
  modifier whenStopped() {
    require(stopped);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function stop() public onlyOwner whenNotStopped {
    stopped = true;
    emit Stop();
  }
}


/**
 * @title Eth2Phone Escrow Contract
 * @dev Contract allows to send ether through verifier (owner of contract).
 * 
 * Only verifier can initiate withdrawal to recipient's address. 
 * Verifier cannot choose recipient's address without 
 * transit private key generated by sender. 
 * 
 * Sender is responsible to provide transit private key
 * to recipient off-chain.
 * 
 * Recepient signs address to receive with transit private key and 
 * provides signed address to verification server. 
 * (See VerifyTransferSignature method for details.)
 * 
 * Verifier verifies off-chain the recipient in accordance with verification 
 * conditions (e.g., phone ownership via SMS authentication) and initiates
 * withdrawal to the address provided by recipient.
 * (See withdraw method for details.)
 * 
 * Verifier charges commission for it's services.
 * 
 * Sender is able to cancel transfer if it's not yet cancelled or withdrawn
 * by recipient.
 * (See cancelTransfer method for details.)
 */
contract e2pEscrow is Stoppable, SafeMath {

  // fixed amount of wei accrued to verifier with each transfer
  uint public commissionFee;

  // verifier can withdraw this amount from smart-contract
  uint public commissionToWithdraw; // in wei

  // verifier's address
  address public verifier;
    
  /*
   * EVENTS
   */
  event LogDeposit(
		   address indexed sender,
		   address indexed transitAddress,
		   uint amount,
		      uint commission
		   );

  event LogCancel(
		  address indexed sender,
		  address indexed transitAddress
		  );

  event LogWithdraw(
		    address indexed sender,
		    address indexed transitAddress,
		    address indexed recipient,
		    uint amount
		    );

  event LogWithdrawCommission(uint commissionAmount);

  event LogChangeFixedCommissionFee(
				    uint oldCommissionFee,
				    uint newCommissionFee
				    );
  
  event LogChangeVerifier(
			  address oldVerifier,
			  address newVerifier
			  );  
  
  struct Transfer {
    address from;
    uint amount; // in wei
  }

  // Mappings of transitAddress => Transfer Struct
  mapping (address => Transfer) transferDct;


  /**
   * @dev Contructor that sets msg.sender as owner (verifier) in Ownable
   * and sets verifier's fixed commission fee.
   * @param _commissionFee uint Verifier's fixed commission for each transfer
   */
  constructor(uint _commissionFee, address _verifier) public {
    commissionFee = _commissionFee;
    verifier = _verifier;
  }


  modifier onlyVerifier() {
    require(msg.sender == verifier);
    _;
  }
  
  /**
   * @dev Deposit ether to smart-contract and create transfer.
   * Transit address is assigned to transfer by sender. 
   * Recipient should sign withrawal address with the transit private key 
   * 
   * @param _transitAddress transit address assigned to transfer.
   * @return True if success.
   */
  function deposit(address _transitAddress)
                            public
                            whenNotPaused
                            whenNotStopped
                            payable
    returns(bool)
  {
    // can not override existing transfer
    require(transferDct[_transitAddress].amount == 0);

    require(msg.value > commissionFee);

    // saving transfer details
    transferDct[_transitAddress] = Transfer(
					    msg.sender,
					    safeSub(msg.value, commissionFee)//amount = msg.value - comission
					    );

    // accrue verifier's commission
    commissionToWithdraw = safeAdd(commissionToWithdraw, commissionFee);

    // log deposit event
    emit LogDeposit(msg.sender, _transitAddress, msg.value, commissionFee);
    return true;
  }

  /**
   * @dev Change verifier's fixed commission fee.
   * Only owner can change commision fee.
   * 
   * @param _newCommissionFee uint New verifier's fixed commission
   * @return True if success.
   */
  function changeFixedCommissionFee(uint _newCommissionFee)
                          public
                          whenNotPaused
                          whenNotStopped
                          onlyOwner
    returns(bool success)
  {
    uint oldCommissionFee = commissionFee;
    commissionFee = _newCommissionFee;
    emit LogChangeFixedCommissionFee(oldCommissionFee, commissionFee);
    return true;
  }

  
  /**
   * @dev Change verifier's address.
   * Only owner can change verifier's address.
   * 
   * @param _newVerifier address New verifier's address
   * @return True if success.
   */
  function changeVerifier(address _newVerifier)
                          public
                          whenNotPaused
                          whenNotStopped
                          onlyOwner
    returns(bool success)
  {
    address oldVerifier = verifier;
    verifier = _newVerifier;
    emit LogChangeVerifier(oldVerifier, verifier);
    return true;
  }

  
  /**
   * @dev Transfer accrued commission to verifier's address.
   * @return True if success.
   */
  function withdrawCommission()
                        public
                        whenNotPaused
    returns(bool success)
  {
    uint commissionToTransfer = commissionToWithdraw;
    commissionToWithdraw = 0;
    owner.transfer(commissionToTransfer); // owner is verifier

    emit LogWithdrawCommission(commissionToTransfer);
    return true;
  }

  /**
   * @dev Get transfer details.
   * @param _transitAddress transit address assigned to transfer
   * @return Transfer details (id, sender, amount)
   */
  function getTransfer(address _transitAddress)
            public
            constant
    returns (
	     address id,
	     address from, // transfer sender
	     uint amount) // in wei
  {
    Transfer memory transfer = transferDct[_transitAddress];
    return (
	    _transitAddress,
	    transfer.from,
	        transfer.amount
	    );
  }


  /**
   * @dev Cancel transfer and get sent ether back. Only transfer sender can
   * cancel transfer.
   * @param _transitAddress transit address assigned to transfer
   * @return True if success.
   */
  function cancelTransfer(address _transitAddress) public returns (bool success) {
    Transfer memory transferOrder = transferDct[_transitAddress];

    // only sender can cancel transfer;
    require(msg.sender == transferOrder.from);

    delete transferDct[_transitAddress];
    
    // transfer ether to recipient's address
    msg.sender.transfer(transferOrder.amount);

    // log cancel event
    emit LogCancel(msg.sender, _transitAddress);
    
    return true;
  }

  /**
   * @dev Verify that address is signed with correct verification private key.
   * @param _transitAddress transit address assigned to transfer
   * @param _recipient address Signed address.
   * @param _v ECDSA signature parameter v.
   * @param _r ECDSA signature parameters r.
   * @param _s ECDSA signature parameters s.
   * @return True if signature is correct.
   */
  function verifySignature(
			   address _transitAddress,
			   address _recipient,
			   uint8 _v,
			   bytes32 _r,
			   bytes32 _s)
    public pure returns(bool success)
  {
    bytes32 prefixedHash = keccak256("\x19Ethereum Signed Message:\n32", _recipient);
    address retAddr = ecrecover(prefixedHash, _v, _r, _s);
    return retAddr == _transitAddress;
  }

  /**
   * @dev Verify that address is signed with correct private key for
   * verification public key assigned to transfer.
   * @param _transitAddress transit address assigned to transfer
   * @param _recipient address Signed address.
   * @param _v ECDSA signature parameter v.
   * @param _r ECDSA signature parameters r.
   * @param _s ECDSA signature parameters s.
   * @return True if signature is correct.
   */
  function verifyTransferSignature(
				   address _transitAddress,
				   address _recipient,
				   uint8 _v,
				   bytes32 _r,
				   bytes32 _s)
    public pure returns(bool success)
  {
    return (verifySignature(_transitAddress,
			    _recipient, _v, _r, _s));
  }

  /**
   * @dev Withdraw transfer to recipient's address if it is correctly signed
   * with private key for verification public key assigned to transfer.
   * 
   * @param _transitAddress transit address assigned to transfer
   * @param _recipient address Signed address.
   * @param _v ECDSA signature parameter v.
   * @param _r ECDSA signature parameters r.
   * @param _s ECDSA signature parameters s.
   * @return True if success.
   */
  function withdraw(
		    address _transitAddress,
		    address _recipient,
		    uint8 _v,
		    bytes32 _r,
		    bytes32 _s
		    )
    public
    onlyVerifier // only through verifier can withdraw transfer;
    whenNotPaused
    whenNotStopped
    returns (bool success)
  {
    Transfer memory transferOrder = transferDct[_transitAddress];

    // verifying signature
    require(verifySignature(_transitAddress,
		     _recipient, _v, _r, _s ));

    delete transferDct[_transitAddress];

    // transfer ether to recipient's address
    _recipient.transfer(transferOrder.amount);

    // log withdraw event
    emit LogWithdraw(transferOrder.from, _transitAddress, _recipient, transferOrder.amount);

    return true;
  }

  // fallback function - do not receive ether by default
  function() public payable {
    revert();
  }
}