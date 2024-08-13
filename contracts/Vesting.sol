// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    // function _msgData() internal view virtual returns (bytes calldata) {
    //     return msg.data;
    // }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    // function renounceOwnership() public virtual onlyOwner {
    //     _transferOwnership(address(0));
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "New owner address cannot be zero"
        );
        
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
    address owneraddress = owner();
    require(newOwner != address(0), "New owner is same 0");
    require(newOwner != owneraddress, "New owner is same as old"); // Using cached variable _owner
    emit OwnershipTransferred(owneraddress, newOwner); // Using cached variable _owner
    _owner = newOwner;
    }
}

abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnerChanged(address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * Functionality to transfer contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
    address _owner = owner();
    require(newOwner != address(0), "New owner is same 0");
    require(newOwner != _owner, "New owner is same as old"); // Using cached variable _owner
    address pending = _pendingOwner;
    if (newOwner != pending) {
        emit OwnershipTransferred(_owner, newOwner); // Using cached variable _owner
        _pendingOwner = newOwner;
    }
}

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        emit OwnerChanged(newOwner);
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

contract Vesting is Ownable2Step {
    struct VestingInfo {
        uint256 allocatedAmount;
        uint256 claimedAmount;
        uint256 nextClaimTimestamp;
        uint256 claimEndTimestamp;
    }

    struct UserInfo {
        address wallet;
        uint256 totalAllocatedAmount;
        uint256 totalClaimedAmount;
        // uint256 vestingCount;
    }

    // IERC20 public token;
    uint256 public adminComm;
    uint256 public claimEndDay;
    uint256 public vestingEndDay;
    uint256 public endDay;
    bool public locked;

    mapping(address => UserInfo) public userInfo;
    mapping(address => VestingInfo[]) private userVestingInfo;
    mapping(address => bool) public allocatedUser;

    event Withdraw(uint256 indexed amount);
    event AdminChanged(uint256 indexed user);
    event VestingDayChanged(uint256 indexed vestingEndDay, uint256 indexed endDay);

    constructor(
        uint256 _adminComm,
        uint256 _vestingEndDay,
        uint256 _claimEndDay
    ) payable {
        // token = IERC20(_token);
        require(_vestingEndDay != 0, "Vesting end day is zero");
        require(_claimEndDay != 0, "Claim end day is zero");
        adminComm = _adminComm;
        vestingEndDay = _vestingEndDay * 86400;
        claimEndDay = _claimEndDay * 86400;
        endDay = _claimEndDay;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }


    function updateAdminCommission(uint256 commission) external payable  onlyOwner noReentrant {
        require(adminComm != commission, "New value same as old");
        emit AdminChanged(commission);
        adminComm = commission;
    }

    function updateVestingDays(
        uint256 inputVestingEndDay,
        uint256 inputClaimEndDay
    ) external payable onlyOwner noReentrant {
        require(inputVestingEndDay != 0, "Vesting end day is zero");
        require(inputVestingEndDay != vestingEndDay, "Vesting end value is same as old");
        require(inputClaimEndDay != 0, "Claim end day is zero");
        require(inputClaimEndDay != claimEndDay, "Claim end value is same as old");
        emit VestingDayChanged(vestingEndDay, endDay);
        vestingEndDay = inputVestingEndDay * 86400;
        claimEndDay = inputClaimEndDay * 86400;
        endDay = inputClaimEndDay;
    }

    function allocateForVesting(address userAddress) external payable onlyOwner noReentrant {
        // require(
        //     !allocatedUser[userAddress],
        //     "vesting already allocated to this address"
        // );
        //token.transferFrom(msg.sender, address(this), _amount);

        //_allocateAmount(userAddress, msg.value);
        allocatedUser[userAddress] = true;
    //}

    //function _allocateAmount(address userAddress, uint256 _amount) internal {
        UserInfo storage user = userInfo[userAddress];
        VestingInfo[] storage vestingInfo = userVestingInfo[userAddress];

        // uint256 duration = 1 days;
        uint256 vestingStartTimestamp = block.timestamp + vestingEndDay; //Changes

        user.wallet = userAddress;

        if (allocatedUser[userAddress]) {
            user.totalAllocatedAmount += msg.value;
            user.totalClaimedAmount = user.totalClaimedAmount;
        } else {
            user.totalAllocatedAmount = msg.value;
            user.totalClaimedAmount = 0;
        }

        // vestingInfo[vestingInfo.length].nextClaimTimestamp = vestingStartTimestamp;
        // vestingInfo[vestingInfo.length].tokensUnlockedAmount = 0;

        vestingInfo.push(
            VestingInfo({
                allocatedAmount: msg.value,
                claimedAmount: 0,
                nextClaimTimestamp: vestingStartTimestamp,
                claimEndTimestamp: vestingStartTimestamp + claimEndDay //Changes
            })
        );

        allocatedUser[userAddress] = true;
    }

    function claimTokens(address user, uint256 id) public noReentrant {
        require(allocatedUser[user], "Funds not allocated to this user");

        UserInfo storage u = userInfo[user];
        VestingInfo storage v  = userVestingInfo[user][id];
        assert(u.wallet != address(0));
        // uint timestamp = userVestingInfo[_user][_id].nextClaimTimestamp;
        // require(block.timestamp >= timestamp, "Cannot claim before claim start time");

        (uint256 tokensToSend, uint256 numberOfDays) = getUnlockedTokenAmount(
            u.wallet,
            id
        );

        // tokensToSend = tokensToSend - user.claimedAmount;

        if (tokensToSend > 0) {
            uint256 fee = (tokensToSend * adminComm) / 10000;

            // token.transfer(_user, tokensToSend);
            // payable(_user).transfer(tokensToSend);
            //require(sent, "Failed to send Ether");
            payable(owner()).transfer(fee);
            payable(user).transfer(tokensToSend - fee);
            emit Withdraw(tokensToSend);
            u.totalClaimedAmount += tokensToSend;
            u.totalAllocatedAmount -= tokensToSend;
            v.claimedAmount += tokensToSend;

        }

        uint256 nextClaimTime =v.nextClaimTimestamp +
            (numberOfDays * 86400);

        if (
           v.claimedAmount ==
           v.allocatedAmount
        ) {
           v.nextClaimTimestamp = 0;
        } else {
            v.nextClaimTimestamp = nextClaimTime;
        }
    }

    function claimTotalTokens(address user, uint256 id) external payable onlyOwner noReentrant {
        UserInfo storage u= userInfo[user];
        require(u.wallet != address(0), "Invalid user");
        VestingInfo storage v  = userVestingInfo[user][id];
        uint256 leftBalance = v.allocatedAmount -
            v.claimedAmount;
        uint fee = 0;
        if (leftBalance >= 1) {
            fee = (leftBalance * adminComm) / 10000;

            v.nextClaimTimestamp = 0;
            u.totalClaimedAmount += leftBalance;
            u.totalAllocatedAmount -= leftBalance;
            v.claimedAmount += leftBalance;
            v.allocatedAmount -= leftBalance;

            // token.transfer(owner(), fee);
            // token.transfer(user, leftBalance - fee);
            if (fee != 0) {
                payable(owner()).transfer(fee);
                
            }

            uint balance  = leftBalance - fee;
            emit Withdraw(balance);
            if(balance != 0)
            {
                payable(user).transfer(balance);
            }
        }
    }

        function getUnlockedTokenAmount(
        address wallet,
        uint256 id
    ) public view returns (uint256, uint256) {
        VestingInfo[] memory vestingInfo = userVestingInfo[wallet];

        uint256 allowedAmount = 0;
        uint256 numberOfDays = 0;

        if (!allocatedUser[wallet]) {
            return (0, 0);
        }

        uint256 allocatedAmount = userVestingInfo[wallet][id].allocatedAmount;
        uint256 claimedAmount = userVestingInfo[wallet][id].claimedAmount;
        uint256 nextClaimTimestamp = vestingInfo[id].nextClaimTimestamp;
        uint256 claimEndTimestamp = vestingInfo[id].claimEndTimestamp;

        uint blockValue = block.timestamp;

        if (blockValue >= nextClaimTimestamp) {
            if (nextClaimTimestamp != 0) {
                uint256 fromTime = blockValue > claimEndTimestamp
                    ? claimEndTimestamp - 86400
                    : blockValue;
                uint256 duration = (fromTime - nextClaimTimestamp) + 86400;
                numberOfDays = duration / 86400;

                allowedAmount = (allocatedAmount * numberOfDays) / endDay;
            }
        }

        // allowedAmount = allowedAmount - user.claimedAmount;

        if (allowedAmount >= (allocatedAmount - claimedAmount)) {
            allowedAmount = (allocatedAmount - claimedAmount);
        }

        return (allowedAmount, numberOfDays);
    }

    function getVestingInfo(
        address userAddress,
        uint256 id
    ) public view returns (VestingInfo memory) {
        return userVestingInfo[userAddress][id];
    }

    function getUserTotalVesting(address userAddress) public view returns (uint256) {
        return userVestingInfo[userAddress].length;
    }

    function drainTokens(uint256 _amount) external payable onlyOwner noReentrant{
        // token.transfer(msg.sender, _amount);
        payable(owner()).transfer(_amount);
    }

    function updateVestingStartTimestamp(
        address user,
        uint256 id,
        uint256 _newVestingStartTimestamp
    ) external payable onlyOwner noReentrant{
        assert(
            _newVestingStartTimestamp != 0
        );
        //require(userVestingInfo[_user].length > index, "Invalid index");
        assert(user != address(0));
        VestingInfo storage v  = userVestingInfo[user][id];
        v.nextClaimTimestamp = _newVestingStartTimestamp;
        v.claimEndTimestamp =
            _newVestingStartTimestamp +
            claimEndDay;
    }

     function withdraw() public onlyOwner noReentrant{
        payable(owner()).transfer(address(this).balance);
    }
}
