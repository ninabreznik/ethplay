/**
 *Submitted for verification at Etherscan.io on 2018-06-25
*/

pragma solidity ^0.4.23;

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xc,..,lxKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOo:'........':dOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMN0xl,....';:,........;lxKNMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMWXOo:'....,:lxOk:...........':dOXWMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMNKxl;.....;cokOOOOd;...............;lkKWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWXOd:'....':lxkOOOkdc;'...................':dONWMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMWKkl;.....,coxOOOOxo:,...........................;lkKWMMMMMMMMMMMMM
MMMMMMMMMWNOdc'....':ldkOOOkdl;'.................................,cd0NWMMMMMMMMM
MMMMMMWKkl;.....,coxOOOOxoc,.........................................;okXWMMMMMM
MMMMXxc,....';ldkOOOkdl;'...............................................,ckNMMMM
MMMM0;...'coxOOOOxoc,.....................................................;0MMMM
MMMM0;..'oOOOkdl:'................................,;,,.............':l:...;0MMMM
MMMM0;..'oOOOl'..................................,dOOd,...........:xOOo...;0MMMM
MMMM0;..'oOOOc...':ccccccccccccc:;,...........';:okOOkl:;'........lOOOo...;0MMMM
MMMM0;..'oOOOc...;k0OOOOOOOOOOOOOOko;......':oxOOOOOOOOOOxo:'.....lOOOo'..;0MMMM
MMMM0;..'oOOOc...':lxOOkocccccccoxOOk:....,dOOOkdolclloxkOOOd,....lOOOo...;0MMMM
MMMM0;..'oOOOc......lOOk;........:xOOd'...lOOOd;........;okxl,....lOOOo...;0MMMM
MMMM0;..'oOOOc......lOOk;........:xOOo'...lOOOd;'.........,.......lOOOo...;0MMMM
MMMM0;..'oOOOc......lOOOocccccclokOOd;....,dO0Okxdolc:;,'.........lOOOo...;0MMMM
MMMM0;..'oOOOc......lOOOOOOOOOOOOOOx:......':oxkOOOOOOOkxdl;'.....lOOOo...;0MMMM
MMMM0;..'oOOOc......lOOOdccccccldkOOxc.........,;:clodxkOOOOd;....lOOOo...;0MMMM
MMMM0;..'oOOOc......lOOk;........,dOOk:................,:dOOOo'...lOOOo...;0MMMM
MMMM0;..'oOOOc......lOOk:.........cOOOl'.,coxl'..........ckOOx,...lOOOo...;0MMMM
MMMM0;..'oOOOc....',oOOkc'''''',;lxOOkc..;xOOOxoc:;,,;:cokOOkl....lOOOo...;0MMMM
MMMM0;..'oOOOc...;dkOOOOkkkkxkkkOOOOkc'...,lxOOOOOOkOOOOOOkd:.....lOOOo...;0MMMM
MMMM0;..'oOOOc...;dxxxxxxxxxxxxxxdoc,.......';codxOOOOxdlc;.......lOOOo...;0MMMM
MMMM0;..'oOOkc.....'''''''''''''.................;xO0x;...........lOOOo...;0MMMM
MMMM0;..'lxl:'...................................':cc:.........';lxOOOo...;0MMMM
MMMM0;...''.................................................,:oxOOOOko;...;0MMMM
MMMMKl'.................................................';ldkOOOkxl:'....'oXMMMM
MMMMMNKxl,...........................................,:oxOOOOkoc;'....;lxKWMMMMM
MMMMMMMMWXOo:'...................................';cdkOOOkxl:,....':dOXWMMMMMMMM
MMMMMMMMMMMMN0xc,.............................,:lxkOOOkdc;'....,lxKNMMMMMMMMMMMM
MMMMMMMMMMMMMMMWXko:'.....................';cdkOOOkxo:,....':oOXWMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMN0xc,...............,:lxkOOOkdc;'....,cx0NMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMWXko;'...........:xkOOxo:,....':oOXWMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMWN0xc,........;ool;'....,cx0NMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKko;............;okXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0dc,....,cd0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl;;l0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title MultiOwnable
 * @dev The MultiOwnable contract has owners addresses and provides basic authorization control
 * functions, this simplifies the implementation of "users permissions".
 */
contract MultiOwnable {
  address public manager; // address used to set owners
  address[] public owners;
  mapping(address => bool) public ownerByAddress;

  event SetOwners(address[] owners);

  modifier onlyOwner() {
    require(ownerByAddress[msg.sender] == true);
    _;
  }

  /**
    * @dev MultiOwnable constructor sets the manager
    */
  constructor() public {
    manager = msg.sender;
  }

  /**
    * @dev Function to set owners addresses
    */
  function setOwners(address[] _owners) public {
    require(msg.sender == manager);
    _setOwners(_owners);
  }

  function _setOwners(address[] _owners) internal {
    for(uint256 i = 0; i < owners.length; i++) {
      ownerByAddress[owners[i]] = false;
    }

    for(uint256 j = 0; j < _owners.length; j++) {
      ownerByAddress[_owners[j]] = true;
    }
    owners = _owners;
    emit SetOwners(_owners);
  }

  function getOwners() public view returns (address[]) {
    return owners;
  }
}

/* solium-disable security/no-low-level-calls */

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title ERC827 interface, an extension of ERC20 token standard
 *
 * @dev Interface of a ERC827 token, following the ERC20 standard with extra
 * @dev methods to transfer value and data and execute calls in transfers and
 * @dev approvals.
 */
contract ERC827 is ERC20 {
  function approveAndCall(
    address _spender,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool);

  function transferAndCall(
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool);

  function transferFromAndCall(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title ERC827, an extension of ERC20 token standard
 *
 * @dev Implementation the ERC827, following the ERC20 standard with extra
 * @dev methods to transfer value and data and execute calls in transfers and
 * @dev approvals.
 *
 * @dev Uses OpenZeppelin StandardToken.
 */
contract ERC827Token is ERC827, StandardToken {

  /**
   * @dev Addition to ERC20 token methods. It allows to
   * @dev approve the transfer of value and execute a call with the sent data.
   *
   * @dev Beware that changing an allowance with this method brings the risk that
   * @dev someone may use both the old and the new allowance by unfortunate
   * @dev transaction ordering. One possible solution to mitigate this race condition
   * @dev is to first reduce the spender's allowance to 0 and set the desired value
   * @dev afterwards:
   * @dev https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * @param _spender The address that will spend the funds.
   * @param _value The amount of tokens to be spent.
   * @param _data ABI-encoded contract call to call `_to` address.
   *
   * @return true if the call function was executed successfully
   */
  function approveAndCall(
    address _spender,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_spender != address(this));

    super.approve(_spender, _value);

    // solium-disable-next-line security/no-call-value
    require(_spender.call.value(msg.value)(_data));

    return true;
  }

  /**
   * @dev Addition to ERC20 token methods. Transfer tokens to a specified
   * @dev address and execute a call with the sent data on the same transaction
   *
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   * @param _data ABI-encoded contract call to call `_to` address.
   *
   * @return true if the call function was executed successfully
   */
  function transferAndCall(
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_to != address(this));

    super.transfer(_to, _value);

    // solium-disable-next-line security/no-call-value
    require(_to.call.value(msg.value)(_data));
    return true;
  }

  /**
   * @dev Addition to ERC20 token methods. Transfer tokens from one address to
   * @dev another and make a contract call on the same transaction
   *
   * @param _from The address which you want to send tokens from
   * @param _to The address which you want to transfer to
   * @param _value The amout of tokens to be transferred
   * @param _data ABI-encoded contract call to call `_to` address.
   *
   * @return true if the call function was executed successfully
   */
  function transferFromAndCall(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  )
    public payable returns (bool)
  {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

    // solium-disable-next-line security/no-call-value
    require(_to.call.value(msg.value)(_data));
    return true;
  }

  /**
   * @dev Addition to StandardToken methods. Increase the amount of tokens that
   * @dev an owner allowed to a spender and execute a call with the sent data.
   *
   * @dev approve should be called when allowed[_spender] == 0. To increment
   * @dev allowed value is better to use this function to avoid 2 calls (and wait until
   * @dev the first transaction is mined)
   * @dev From MonolithDAO Token.sol
   *
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   * @param _data ABI-encoded contract call to call `_spender` address.
   */
  function increaseApprovalAndCall(
    address _spender,
    uint _addedValue,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

    // solium-disable-next-line security/no-call-value
    require(_spender.call.value(msg.value)(_data));

    return true;
  }

  /**
   * @dev Addition to StandardToken methods. Decrease the amount of tokens that
   * @dev an owner allowed to a spender and execute a call with the sent data.
   *
   * @dev approve should be called when allowed[_spender] == 0. To decrement
   * @dev allowed value is better to use this function to avoid 2 calls (and wait until
   * @dev the first transaction is mined)
   * @dev From MonolithDAO Token.sol
   *
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   * @param _data ABI-encoded contract call to call `_spender` address.
   */
  function decreaseApprovalAndCall(
    address _spender,
    uint _subtractedValue,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

    // solium-disable-next-line security/no-call-value
    require(_spender.call.value(msg.value)(_data));

    return true;
  }

}

contract BitScreenerToken is ERC827Token, MultiOwnable {
  string public name = 'BitScreenerToken';
  string public symbol = 'BITX';
  uint8 public decimals = 18;
  uint256 public totalSupply;
  address public owner;

  bool public allowTransfers = false;
  bool public issuanceFinished = false;

  event AllowTransfersChanged(bool _newState);
  event Issue(address indexed _to, uint256 _value);
  event Burn(address indexed _from, uint256 _value);
  event IssuanceFinished();

  modifier transfersAllowed() {
    require(allowTransfers);
    _;
  }

  modifier canIssue() {
    require(!issuanceFinished);
    _;
  }

  constructor(address[] _owners) public {
    _setOwners(_owners);
  }

  /**
  * @dev Enable/disable token transfers. Can be called only by owners
  * @param _allowTransfers True - allow False - disable
  */
  function setAllowTransfers(bool _allowTransfers) external onlyOwner {
    allowTransfers = _allowTransfers;
    emit AllowTransfersChanged(_allowTransfers);
  }

  function transfer(address _to, uint256 _value) public transfersAllowed returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function transferAndCall(address _to, uint256 _value, bytes _data) public payable transfersAllowed returns (bool) {
    return super.transferAndCall(_to, _value, _data);
  }

  function transferFromAndCall(address _from, address _to, uint256 _value, bytes _data) public payable transfersAllowed returns (bool) {
    return super.transferFromAndCall(_from, _to, _value, _data);
  }

  /**
  * @dev Issue tokens to specified wallet
  * @param _to Wallet address
  * @param _value Amount of tokens
  */
  function issue(address _to, uint256 _value) external onlyOwner canIssue returns (bool) {
    totalSupply = totalSupply.add(_value);
    balances[_to] = balances[_to].add(_value);
    emit Issue(_to, _value);
    emit Transfer(address(0), _to, _value);
    return true;
  }

  /**
  * @dev Finish token issuance
  * @return True if success
  */
  function finishIssuance() public onlyOwner returns (bool) {
    issuanceFinished = true;
    emit IssuanceFinished();
    return true;
  }

  /**
  * @dev Burn tokens
  * @param _value Amount of tokens to burn
  */
  function burn(uint256 _value) external {
    require(balances[msg.sender] >= _value);
    totalSupply = totalSupply.sub(_value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    emit Transfer(msg.sender, address(0), _value);
    emit Burn(msg.sender, _value);
  }
}