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

    private static Order CreatePaidOrder(int units = 5)
    {
        var address = new AddressBuilder().Build();
        var order = new OrderBuilder(address)
            .AddOne(1, "cup", 10.0m, 0, string.Empty, units)
            .Build();

        order.SetAwaitingValidationStatus();
        order.SetStockConfirmedStatus();
        order.SetPaidStatus();

        return order;
    }

    [TestMethod]
    public void Request_partial_return_reduces_eligible_units_and_sets_status()
    {
        //Arrange
        var order = CreatePaidOrder(units: 5);

        //Act
        order.RequestReturn(new[] { new OrderItemReturnRequest(1, 2) });

        //Assert
        Assert.AreEqual(OrderStatus.ReturnRequested, order.OrderStatus);
        Assert.AreEqual(2, order.OrderItems.Single().ReturnedUnits);
        Assert.AreEqual(3, order.OrderItems.Single().ReturnEligibleUnits);
    }

    [TestMethod]
    public void Request_full_return_returns_all_units()
    {
        //Arrange
        var order = CreatePaidOrder(units: 5);

        //Act
        order.RequestReturn(new[] { new OrderItemReturnRequest(1, 5) });

        //Assert
        Assert.AreEqual(OrderStatus.ReturnRequested, order.OrderStatus);
        Assert.AreEqual(0, order.OrderItems.Single().ReturnEligibleUnits);
    }

    [TestMethod]
    public void Request_return_exceeding_purchased_units_is_rejected()
    {
        //Arrange
        var order = CreatePaidOrder(units: 5);

        //Act - Assert
        Assert.ThrowsException<OrderingDomainException>(
            () => order.RequestReturn(new[] { new OrderItemReturnRequest(1, 6) }));
        Assert.AreEqual(OrderStatus.Paid, order.OrderStatus);
    }

    [TestMethod]
    public void Request_return_for_product_not_in_order_is_rejected()
    {
        //Arrange
        var order = CreatePaidOrder(units: 5);

        //Act - Assert
        Assert.ThrowsException<OrderingDomainException>(
            () => order.RequestReturn(new[] { new OrderItemReturnRequest(999, 1) }));
    }

    [TestMethod]
    public void Request_return_on_a_submitted_order_is_an_invalid_transition()
    {
        //Arrange
        var address = new AddressBuilder().Build();
        var order = new OrderBuilder(address)
            .AddOne(1, "cup", 10.0m, 0, string.Empty, 5)
            .Build();

        //Act - Assert
        Assert.ThrowsException<OrderingDomainException>(
            () => order.RequestReturn(new[] { new OrderItemReturnRequest(1, 1) }));
        Assert.AreEqual(OrderStatus.Submitted, order.OrderStatus);
    }

    [TestMethod]
    public void Second_return_request_can_only_use_remaining_eligible_units()
    {
        //Arrange
        var order = CreatePaidOrder(units: 5);
        order.RequestReturn(new[] { new OrderItemReturnRequest(1, 3) });
        order.SetReturnedStatus();

        //Act - Assert
        // Order is no longer Paid/Shipped after a return completed, so requesting again is invalid.
        Assert.ThrowsException<OrderingDomainException>(
            () => order.RequestReturn(new[] { new OrderItemReturnRequest(1, 1) }));
    }

    [TestMethod]
    public void Set_returned_status_completes_the_return()
    {
        //Arrange
        var order = CreatePaidOrder(units: 5);
        order.RequestReturn(new[] { new OrderItemReturnRequest(1, 2) });

        //Act
        order.SetReturnedStatus();

        //Assert
        Assert.AreEqual(OrderStatus.Returned, order.OrderStatus);
    }

    [TestMethod]
    public void Set_returned_status_without_a_pending_return_request_is_rejected()
    {
        //Arrange
        var order = CreatePaidOrder(units: 5);

        //Act - Assert
        Assert.ThrowsException<OrderingDomainException>(() => order.SetReturnedStatus());
    }
}
