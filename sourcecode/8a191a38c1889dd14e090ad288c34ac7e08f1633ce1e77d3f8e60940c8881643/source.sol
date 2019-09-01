/**
 *Submitted for verification at Etherscan.io on 2019-04-29
*/

pragma solidity 0.5.6;

library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
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
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

contract IERC20Releasable {
  function release() public;
}

contract IOwnable {
  function isOwner(address who)
    public view returns(bool);

  function _isOwner(address)
    internal view returns(bool);
}

contract SingleOwner is IOwnable {
  address public owner;

  constructor(
    address _owner
  )
    internal
  {
    require(_owner != address(0), 'owner_req');
    owner = _owner;

    emit OwnershipTransferred(address(0), owner);
  }

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier ownerOnly() {
    require(msg.sender == owner, 'owner_access');
    _;
  }

  function _isOwner(address _sender)
    internal
    view
    returns(bool)
  {
    return owner == _sender;
  }

  function isOwner(address _sender)
    public
    view
    returns(bool)
  {
    return _isOwner(_sender);
  }

  function setOwner(address _owner)
    public
    ownerOnly
  {
    address prevOwner = owner;
    owner = _owner;

    emit OwnershipTransferred(owner, prevOwner);
  }
}
contract Privileged {
  /// List of privileged users who can transfer token before release
  mapping(address => bool) privileged;

  function isPrivileged(address _addr)
    public
    view
    returns(bool)
  {
    return privileged[_addr];
  }

  function _setPrivileged(address _addr)
    internal
  {
    require(_addr != address(0), 'addr_req');

    privileged[_addr] = true;
  }

  function _setUnprivileged(address _addr)
    internal
  {
    privileged[_addr] = false;
  }
}

contract IToken is IERC20, IERC20Releasable, IOwnable {}

contract MBN is IToken, ERC20, SingleOwner, Privileged {
  string public name = 'Membrana';
  string public symbol = 'MBN';
  uint8 public decimals = 18;
  bool public isReleased;
  uint public releaseDate;

  constructor(address _owner)
    public
    SingleOwner(_owner)
  {
    super._mint(owner, 1000000000 * 10 ** 18);
  }

  // Modifiers
  modifier releasedOnly() {
    require(isReleased, 'released_only');
    _;
  }

  modifier notReleasedOnly() {
    require(! isReleased, 'not_released_only');
    _;
  }

  modifier releasedOrPrivilegedOnly() {
    require(isReleased || isPrivileged(msg.sender), 'released_or_privileged_only');
    _;
  }

  // Methods

  function transfer(address to, uint256 value)
    public
    releasedOrPrivilegedOnly
    returns (bool)
  {
    return super.transfer(to, value);
  }

  function transferFrom(address from, address to, uint256 value)
    public
    releasedOnly
    returns (bool)
  {
    return super.transferFrom(from, to, value);
  }

  function approve(address spender, uint256 value)
    public
    releasedOnly
    returns (bool)
  {
    return super.approve(spender, value);
  }

  function increaseAllowance(address spender, uint addedValue)
    public
    releasedOnly
    returns (bool)
  {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(address spender, uint subtractedValue)
    public
    releasedOnly
    returns (bool)
  {
    return super.decreaseAllowance(spender, subtractedValue);
  }

  function release()
    public
    ownerOnly
    notReleasedOnly
  {
    isReleased = true;
    releaseDate = now;
  }

  function setPrivileged(address _addr)
    public
    ownerOnly
  {
    _setPrivileged(_addr);
  }

  function setUnprivileged(address _addr)
    public
    ownerOnly
  {
    _setUnprivileged(_addr);
  }
}