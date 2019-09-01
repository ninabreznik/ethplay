) {
        foundersAddress = _foundersAddress;
        supportAddress = _supportAddress;
        bountyAddress = _bountyAddress;
    }

    /*
     * @dev Perform initial token allocation between founders' addresses.
     * Is only executed once after presale contract deployment and is invoked manually.
     */
    function allocateInternalWallets() onlyOwner {
        require (!allocatedInternalWallets);

        allocatedInternalWallets = true;

        token.transfer(foundersAddress, initialFoundersAmount);
        token.transfer(supportAddress, initialSupportAmount);
        token.transfer(bountyAddress, initialBountyAmount);
    }
    
    /*
     * @dev HoQu Token factory.
     */
    function createToken(uint256 _totalSupply) internal returns (HoQuToken) {
        return new HoQuToken(_totalSupply);
    }
}