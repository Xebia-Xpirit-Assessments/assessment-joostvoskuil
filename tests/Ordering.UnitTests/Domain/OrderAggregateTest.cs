namespace eShop.Ordering.UnitTests.Domain;

using eShop.Ordering.Domain.AggregatesModel.OrderAggregate;
using eShop.Ordering.UnitTests.Domain;

[TestClass]
public class OrderAggregateTest
{
    public OrderAggregateTest()
    { }

    [TestMethod]
    public void Create_order_item_success()
    {
        //Arrange    
        var productId = 1;
        var productName = "FakeProductName";
        var unitPrice = 12;
        var discount = 15;
        var pictureUrl = "FakeUrl";
        var units = 5;

        //Act 
        var fakeOrderItem = new OrderItem(productId, productName, unitPrice, discount, pictureUrl, units);

        //Assert
        Assert.IsNotNull(fakeOrderItem);
    }

    [TestMethod]
    public void Invalid_number_of_units()
    {
        //Arrange    
        var productId = 1;
        var productName = "FakeProductName";
        var unitPrice = 12;
        var discount = 15;
        var pictureUrl = "FakeUrl";
        var units = -1;

        //Act - Assert
        Assert.ThrowsException<OrderingDomainException>(() => new OrderItem(productId, productName, unitPrice, discount, pictureUrl, units));
    }

    [TestMethod]
    public void Invalid_total_of_order_item_lower_than_discount_applied()
    {
        //Arrange    
        var productId = 1;
        var productName = "FakeProductName";
        var unitPrice = 12;
        var discount = 15;
        var pictureUrl = "FakeUrl";
        var units = 1;
        
        //Act - Assert
        Assert.ThrowsException<OrderingDomainException>(() => new OrderItem(productId, productName, unitPrice, discount, pictureUrl, units));       
    }

    [TestMethod]
    public void Invalid_discount_setting()
    {
        //Arrange    
        var productId = 1;
        var productName = "FakeProductName";
        var unitPrice = 12;
        var discount = 15;
        var pictureUrl = "FakeUrl";
        var units = 5;

        //Act 
        var fakeOrderItem = new OrderItem(productId, productName, unitPrice, discount, pictureUrl, units);

        //Assert
        Assert.ThrowsException<OrderingDomainException>(() => fakeOrderItem.SetNewDiscount(-1));
    }

    [TestMethod]
    public void Invalid_units_setting()
    {
        //Arrange    
        var productId = 1;
        var productName = "FakeProductName";
        var unitPrice = 12;
        var discount = 15;
        var pictureUrl = "FakeUrl";
        var units = 5;

        //Act 
        var fakeOrderItem = new OrderItem(productId, productName, unitPrice, discount, pictureUrl, units);

        //Assert
        Assert.ThrowsException<OrderingDomainException>(() => fakeOrderItem.AddUnits(-1));
    }

    [TestMethod]
    public void when_add_two_times_on_the_same_item_then_the_total_of_order_should_be_the_sum_of_the_two_items()
    {
        var address = new AddressBuilder().Build();
        var order = new OrderBuilder(address)
            .AddOne(1, "cup", 10.0m, 0, string.Empty)
            .AddOne(1, "cup", 10.0m, 0, string.Empty)
            .Build();

        Assert.AreEqual(20.0m, order.GetTotal());
    }

    [TestMethod]
    public void Add_new_Order_raises_new_event()
    {
        //Arrange
        var street = "fakeStreet";
        var city = "FakeCity";
        var state = "fakeState";
        var country = "fakeCountry";
        var zipcode = "FakeZipCode";
        var cardTypeId = 5;
        var cardNumber = "12";
        var cardSecurityNumber = "123";
        var cardHolderName = "FakeName";
        var cardExpiration = DateTime.UtcNow.AddYears(1);
        var expectedResult = 1;

        //Act 
        var fakeOrder = new Order("1", "fakeName", new Address(street, city, state, country, zipcode), cardTypeId, cardNumber, cardSecurityNumber, cardHolderName, cardExpiration);

        //Assert
        Assert.AreEqual(fakeOrder.DomainEvents.Count, expectedResult);
    }

    [TestMethod]
    public void Add_event_Order_explicitly_raises_new_event()
    {
        //Arrange   
        var street = "fakeStreet";
        var city = "FakeCity";
        var state = "fakeState";
        var country = "fakeCountry";
        var zipcode = "FakeZipCode";
        var cardTypeId = 5;
        var cardNumber = "12";
        var cardSecurityNumber = "123";
        var cardHolderName = "FakeName";
        var cardExpiration = DateTime.UtcNow.AddYears(1);
        var expectedResult = 2;

        //Act 
        var fakeOrder = new Order("1", "fakeName", new Address(street, city, state, country, zipcode), cardTypeId, cardNumber, cardSecurityNumber, cardHolderName, cardExpiration);
        fakeOrder.AddDomainEvent(new OrderStartedDomainEvent(fakeOrder, "fakeName", "1", cardTypeId, cardNumber, cardSecurityNumber, cardHolderName, cardExpiration));
        //Assert
        Assert.AreEqual(fakeOrder.DomainEvents.Count, expectedResult);
    }

    [TestMethod]
    public void RequestReturn_partial_quantity_moves_order_to_ReturnRequested()
    {
        //Arrange
        var address = new AddressBuilder().Build();
        var order = new OrderBuilder(address)
            .AddOne(1, "cup", 10.0m, 0, string.Empty, units: 5)
            .Build();
        MoveOrderToPaidStatus(order);

        //Act
        order.RequestReturn(new Dictionary<int, int> { [1] = 2 });

        //Assert
        Assert.AreEqual(OrderStatus.ReturnRequested, order.OrderStatus);
        Assert.AreEqual(2, order.OrderItems.Single(oi => oi.ProductId == 1).ReturnedUnits);
    }

    [TestMethod]
    public void RequestReturn_full_quantity_returns_all_units()
    {
        //Arrange
        var address = new AddressBuilder().Build();
        var order = new OrderBuilder(address)
            .AddOne(1, "cup", 10.0m, 0, string.Empty, units: 5)
            .Build();
        MoveOrderToPaidStatus(order);

        //Act
        order.RequestReturn(new Dictionary<int, int> { [1] = 5 });

        //Assert
        Assert.AreEqual(OrderStatus.ReturnRequested, order.OrderStatus);
        Assert.AreEqual(5, order.OrderItems.Single(oi => oi.ProductId == 1).ReturnedUnits);
        Assert.AreEqual(0, order.OrderItems.Single(oi => oi.ProductId == 1).EligibleForReturnUnits);
    }

    [TestMethod]
    public void RequestReturn_quantity_exceeding_purchased_units_throws()
    {
        //Arrange
        var address = new AddressBuilder().Build();
        var order = new OrderBuilder(address)
            .AddOne(1, "cup", 10.0m, 0, string.Empty, units: 3)
            .Build();
        MoveOrderToPaidStatus(order);

        //Act - Assert
        Assert.ThrowsException<OrderingDomainException>(() => order.RequestReturn(new Dictionary<int, int> { [1] = 4 }));
    }

    [TestMethod]
    public void RequestReturn_when_order_not_paid_or_shipped_throws()
    {
        //Arrange
        var address = new AddressBuilder().Build();
        var order = new OrderBuilder(address)
            .AddOne(1, "cup", 10.0m, 0, string.Empty, units: 3)
            .Build();

        //Act - Assert (order is still in Submitted status)
        Assert.ThrowsException<OrderingDomainException>(() => order.RequestReturn(new Dictionary<int, int> { [1] = 1 }));
    }

    [TestMethod]
    public void SetRefundedStatus_from_ReturnRequested_succeeds()
    {
        //Arrange
        var address = new AddressBuilder().Build();
        var order = new OrderBuilder(address)
            .AddOne(1, "cup", 10.0m, 0, string.Empty, units: 3)
            .Build();
        MoveOrderToPaidStatus(order);
        order.RequestReturn(new Dictionary<int, int> { [1] = 1 });

        //Act
        order.SetRefundedStatus();

        //Assert
        Assert.AreEqual(OrderStatus.Refunded, order.OrderStatus);
    }

    [TestMethod]
    public void SetRefundedStatus_when_not_ReturnRequested_throws()
    {
        //Arrange
        var address = new AddressBuilder().Build();
        var order = new OrderBuilder(address)
            .AddOne(1, "cup", 10.0m, 0, string.Empty, units: 3)
            .Build();
        MoveOrderToPaidStatus(order);

        //Act - Assert
        Assert.ThrowsException<OrderingDomainException>(() => order.SetRefundedStatus());
    }

    private static void MoveOrderToPaidStatus(Order order)
    {
        order.SetAwaitingValidationStatus();
        order.SetStockConfirmedStatus();
        order.SetPaidStatus();
    }

    [TestMethod]
    public void Remove_event_Order_explicitly()
    {
        //Arrange    
        var street = "fakeStreet";
        var city = "FakeCity";
        var state = "fakeState";
        var country = "fakeCountry";
        var zipcode = "FakeZipCode";
        var cardTypeId = 5;
        var cardNumber = "12";
        var cardSecurityNumber = "123";
        var cardHolderName = "FakeName";
        var cardExpiration = DateTime.UtcNow.AddYears(1);
        var fakeOrder = new Order("1", "fakeName", new Address(street, city, state, country, zipcode), cardTypeId, cardNumber, cardSecurityNumber, cardHolderName, cardExpiration);
        var @fakeEvent = new OrderStartedDomainEvent(fakeOrder, "1", "fakeName", cardTypeId, cardNumber, cardSecurityNumber, cardHolderName, cardExpiration);
        var expectedResult = 1;

        //Act         
        fakeOrder.AddDomainEvent(@fakeEvent);
        fakeOrder.RemoveDomainEvent(@fakeEvent);
        //Assert
        Assert.AreEqual(fakeOrder.DomainEvents.Count, expectedResult);
    }
}
