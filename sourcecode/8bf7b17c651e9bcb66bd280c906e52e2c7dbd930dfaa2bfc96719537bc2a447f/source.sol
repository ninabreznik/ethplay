period = 5 * 365;
    per_p_sale = 5;
    per_sale = 365;
    sale_pre_sale = 50;
    sale_1_week = 40;
    sale_2_week = 30;
    sale_3_week = 20;
    sale_4_week = 10;
    sale_5_week = 5;
    ini_supply = 100000000 * 1 ether;
    presaleTokens    = 60000000 * 1 ether;
    restrictedTokens = 30000000 * 1 ether;
    
    token.transfer(restricted, restrictedTokens);
  }

  modifier saleIsOn() {
    require(now > start && now < start + period * 1 days);
    _;
  }

  function setStart(uint _start) public onlyOwner {
    start = _start;
  }
  
  function setPeriod(uint _period) public onlyOwner {
    period = _period;
  }  
  
  function setSail(uint _sale_pre_sale, uint _sale_1_week, uint _sale_2_week, uint _sale_3_week, uint _sale_4_week, uint _sale_5_week) public onlyOwner {
    sale_pre_sale = _sale_pre_sale;
    sale_1_week = _sale_1_week;
    sale_2_week = _sale_2_week;
    sale_3_week = _sale_3_week;
    sale_4_week = _sale_4_week;
    sale_5_week = _sale_5_week; 
  }    

  function createTokens() saleIsOn payable public {

    uint tokens = rate.mul(msg.value).div(1 ether);
    uint bonusTokens = 0;
    start_ico = start + per_p_sale * 1 days; 
    multisig.transfer(msg.value);    
    if(now < start_ico) 
    { 
     if(address(this).balance >= ini_supply.sub(restrictedTokens).sub(presaleTokens))
       {
         bonusTokens = tokens.div(100).mul(sale_pre_sale);
       } 
	  
    } else if(now >= start_ico && now < start_ico + (per_sale * 1 days)) {
      bonusTokens = tokens.div(100).mul(sale_1_week);
    } else if(now >= start_ico + (per_sale * 1 days) && now < start_ico + (per_sale * 1 days).mul(2)) {
      bonusTokens = tokens.div(100).mul(sale_2_week);
    } else if(now >= start_ico + (per_sale * 1 days).mul(2) && now < start_ico + (per_sale * 1 days).mul(3)) {
      bonusTokens = tokens.div(100).mul(sale_3_week);  
    } else if(now >= start_ico + (per_sale * 1 days).mul(3) && now < start_ico + (per_sale * 1 days).mul(4)) {
      bonusTokens = tokens.div(100).mul(sale_4_week);       
    } else if(now >= start_ico + (per_sale * 1 days).mul(4) && now < start_ico + (per_sale * 1 days).mul(5)) {
      bonusTokens = tokens.div(100).mul(sale_5_week);      
    }
    uint tokensWithBonus = tokens.add(bonusTokens);
    token.transfer(msg.sender, tokensWithBonus);
    
  }

  function() external payable {
    createTokens();
  }
    
}