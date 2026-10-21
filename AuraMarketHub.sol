// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract AuraMarketHub {
    enum ListingState { Active, Sold, Delisted }

    struct ItemListing {
        string title;
        uint256 price;
        address payable seller;
        ListingState state;
        uint256 totalSales;
        uint256 createdAt;
    }

    struct Feedback {
        uint8 ratingScore; // 1-5
        string reviewText;
        address reviewer;
        uint256 submittedAt;
    }

    address payable public immutable marketplaceOwner;
    string public hubBrandTag;
    uint256 public feePercentageBasisPoints; // 100 = 1%
    uint256 public listingCounter;
    uint256 public accumulatedPlatformFees;

    mapping(uint256 => ItemListing) public listings;
    mapping(uint256 => Feedback[]) private itemReviews;

    event ItemListed(uint256 indexed listingId, string title, uint256 price, address indexed seller);
    event ItemPriceAdjusted(uint256 indexed listingId, uint256 newPrice);
    event ItemStatusToggled(uint256 indexed listingId, ListingState newState);
    event ItemPurchased(uint256 indexed listingId, address indexed buyer, uint256 pricePaid);
    event FeedbackSubmitted(uint256 indexed listingId, address indexed reviewer, uint8 rating);
    event MarketFeeUpdated(uint256 newFeeBasisPoints);
    event BrandTagChanged(string newBrandTag);
    event PlatformFeesHarvested(address indexed receiver, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == marketplaceOwner, "AuraMarket: Unauthorized access");
        _;
    }

    constructor() {
        marketplaceOwner = payable(msg.sender);
        hubBrandTag = "Aura Base Commerce Hub";
        feePercentageBasisPoints = 150; // 1.5%
    }

    // 1. Создать объявление / листинг цифрового слота
    function createListing(string calldata title, uint256 price) external returns (uint256) {
        require(bytes(title).length > 0, "AuraMarket: Empty title");
        require(price > 0, "AuraMarket: Price must be positive");

        listingCounter++;
        listings[listingCounter] = ItemListing({
            title: title,
            price: price,
            seller: payable(msg.sender),
            state: ListingState.Active,
            totalSales: 0,
            createdAt: block.timestamp
        });

        emit ItemListed(listingCounter, title, price, msg.sender);
        return listingCounter;
    }

    // 2. Обновить цену листинга
    function updateListingPrice(uint256 listingId, uint256 newPrice) external {
        ItemListing storage item = listings[listingId];
        require(item.seller == msg.sender, "AuraMarket: Only seller can change price");
        require(item.state == ListingState.Active, "AuraMarket: Listing not active");
        require(newPrice > 0, "AuraMarket: Price must be positive");

        item.price = newPrice;
        emit ItemPriceAdjusted(listingId, newPrice);
    }

    // 3. Снять с продажи или вернуть на витрину
    function toggleListingState(uint256 listingId, bool setDelisted) external {
        ItemListing storage item = listings[listingId];
        require(item.seller == msg.sender, "AuraMarket: Only seller can toggle state");

        if (setDelisted) {
            item.state = ListingState.Delisted;
        } else {
            item.state = ListingState.Active;
        }

        emit ItemStatusToggled(listingId, item.state);
    }

    // 4. Тестовая покупка (отправка ETH с разделением на выплату продавцу и комиссию)
    function buyItem(uint256 listingId) external payable {
        ItemListing storage item = listings[listingId];
        require(listingId > 0 && listingId <= listingCounter, "AuraMarket: Invalid ID");
        require(item.state == ListingState.Active, "AuraMarket: Item not available");
        require(msg.value == item.price, "AuraMarket: Exact price required");

        uint256 fee = (msg.value * feePercentageBasisPoints) / 10000;
        uint256 sellerAmount = msg.value - fee;

        accumulatedPlatformFees += fee;
        item.totalSales++;

        (bool paidSeller, ) = item.seller.call{value: sellerAmount}("");
        require(paidSeller, "AuraMarket: Seller payment failed");

        emit ItemPurchased(listingId, msg.sender, msg.value);
    }

    // 5. Оставить ончейн-отзыв на лот
    function leaveFeedback(uint256 listingId, uint8 rating, string calldata reviewText) external {
        require(listingId > 0 && listingId <= listingCounter, "AuraMarket: Invalid ID");
        require(rating >= 1 && rating <= 5, "AuraMarket: Rating score 1-5");

        itemReviews[listingId].push(Feedback({
            ratingScore: rating,
            reviewText: reviewText,
            reviewer: msg.sender,
            submittedAt: block.timestamp
        }));

        emit FeedbackSubmitted(listingId, msg.sender, rating);
    }

    // 6. Изменить комиссию маркетплейса
    function setPlatformFee(uint256 newFeeBasisPoints) external onlyOwner {
        require(newFeeBasisPoints <= 1000, "AuraMarket: Fee capped at 10%");
        feePercentageBasisPoints = newFeeBasisPoints;
        emit MarketFeeUpdated(newFeeBasisPoints);
    }

    // 7. Обновить брендовое название хаба
    function setHubBrandTag(string calldata newTag) external onlyOwner {
        hubBrandTag = newTag;
        emit BrandTagChanged(newTag);
    }

    // 8. Забрать накопленные комиссии маркетплейса
    function harvestMarketFees() external onlyOwner {
        uint256 available = accumulatedPlatformFees;
        require(available > 0, "AuraMarket: No fees to harvest");

        accumulatedPlatformFees = 0;
        (bool sent, ) = marketplaceOwner.call{value: available}("");
        require(sent, "AuraMarket: Fee harvest failed");

        emit PlatformFeesHarvested(marketplaceOwner, available);
    }

    // Чтение информации о листинге
    function getListingInfo(uint256 listingId) external view returns (
        string memory title,
        uint256 price,
        address seller,
        ListingState state,
        uint256 totalSales,
        uint256 reviewsCount
    ) {
        ItemListing memory item = listings[listingId];
        return (item.title, item.price, item.seller, item.state, item.totalSales, itemReviews[listingId].length);
    }
}