// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract galleryCollection is ERC721URIStorage, ERC721Royalty, ERC721Enumerable, Ownable {
	function mint(string _tokenUri, uint256 _royaltyNumerator, address to) public onlyOwner returns (uint256) {
		uint256 _newTokenId = totalSupply();
		_safeMint(to, _newTokenId);
		_setTokenURI(_newTokenId, _tokenURI);
		_setTokenRoyalty(_newTokenId, msg.sender, _royaltyNumerator);
		_setApprovalForAll(to, msg.sender, true);
		return _newTokenId;	
	}
	function mint(string _tokenUri, uint256 _royaltyNumerator) public onlyOwner returns (uint256) {
		uint256 _newTokenId = totalSupply();
		_mint(msg.sender, _newTokenId);
		_setTokenURI(_newTokenId, _tokenURI);
		_setTokenRoyalty(_newTokenId, msg.sender, _royaltyNumerator);
		return _newTokenId;
	}
}


contract galleryContract is Ownable {

	galleryCollection myCollection;
	
	mapping (uint256 => uint256) public tokenPrices;

	constructor () {
		myCollection = new galleryCollection("Gallery The Rose", "ROSE");
	}

	function publishArtwork(string _tokenUri, uint256 _tokenPrice, address to) public onlyOwner {
		uint256 _newTokenId = myCollection.mint(_tokenUri, to);
		tokenPrices[_newTokenId] = _tokenPrice;
	}

	function publishArtwork(string _tokenUri, uint256 _tokenPrice) public onlyOwner {
		uint256 _newTokenId = myCollection.mint(_tokenUri);
		tokenPrices[_newTokenId] = _tokenPrice;
	}

	function sellArtwork(uint256 _tokenId, uint256 _tokenPrice) public {
		require(myCollection.ownerOf(_tokenId) == msg.sender, "You are trying to sell art you don't own");
		tokenPrices[_tokenId] = _tokenPrice;
	}
	
	function buyArtwork(uint256 _tokenId) public payable {
		uint256 _tokenPrice = tokenPrices[_tokenId];
		require(_tokenPrice > 0, "Token not for sale");
		require(msg.value == _tokenPrice, "Ether received doesn´t match token price");
		address seller = myCollection.ownerOf(_tokenId);
		
		# Operacion atomica
		#  ETH   buyer/msg.sender   ->   galleryContract  ->  seller
		#  NFT   buyer/msg.sender              <-             seller
		myCollection.safeTransferFrom(seller, msg.sender, _tokenId);
		
		# Royalty goes entirely to the gallery
		uint256 amountReceived = msg.value;
		(address royaltyReceiver, uint256 royaltyAmount) = myCollection.royaltyInfo(_tokenId, _tokenPrice);
		uint256 sellerAmount = amountReceived - royaltyAmount;
		
		payable(royaltyReceiver).transfer(royaltyAmount);
		payable(seller).transfer(sellerAmount);
		
		tokenPrices[_tokenId] = 0; # Mark token no longer for sale
	}
	
	
	function withdraw(address to) public onlyOwner {
		uint256 balanceAmount = address(this).balance;
		payable(to).transfer(balanceAmount);
	}	

}