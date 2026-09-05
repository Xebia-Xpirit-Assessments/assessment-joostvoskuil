namespace eShop.Ordering.UnitTests.Application;

using eShop.Ordering.Domain.AggregatesModel.OrderAggregate;

[TestClass]
public class RequestOrderReturnCommandHandlerTest
{
    private readonly IOrderRepository _orderRepositoryMock;
    private readonly IBuyerRepository _buyerRepositoryMock;

    public RequestOrderReturnCommandHandlerTest()
    {
        _orderRepositoryMock = Substitute.For<IOrderRepository>();
        _buyerRepositoryMock = Substitute.For<IBuyerRepository>();
    }

    [TestMethod]
    public async Task Handle_returns_false_when_order_does_not_exist()
    {
        // Arrange
        _orderRepositoryMock.GetAsync(Arg.Any<int>()).Returns(Task.FromResult<Order>(null));
        var handler = new RequestOrderReturnCommandHandler(_orderRepositoryMock, _buyerRepositoryMock);

        // Act
        var result = await handler.Handle(new RequestOrderReturnCommand(1, "buyer-identity", new Dictionary<int, int> { { 1, 1 } }), default);

        // Assert
        Assert.IsFalse(result);
    }

    [TestMethod]
    public async Task Handle_throws_when_requesting_user_is_not_the_order_owner()
    {
        // Arrange
        var order = PaidOrderWithOneItem(units: 5);
        var buyer = new Buyer("owner-identity", "Owner");

        _orderRepositoryMock.GetAsync(Arg.Any<int>()).Returns(Task.FromResult(order));
        _buyerRepositoryMock.FindByIdAsync(Arg.Any<int>()).Returns(Task.FromResult(buyer));

        var handler = new RequestOrderReturnCommandHandler(_orderRepositoryMock, _buyerRepositoryMock);

        // Act - Assert
        await Assert.ThrowsExceptionAsync<OrderingDomainException>(() =>
            handler.Handle(new RequestOrderReturnCommand(order.Id, "someone-else-identity", new Dictionary<int, int> { { 1, 1 } }), default));
    }

    [TestMethod]
    public async Task Handle_requests_partial_return_for_own_order_successfully()
    {
        // Arrange
        var order = PaidOrderWithOneItem(units: 5);
        var buyer = new Buyer("owner-identity", "Owner");

        _orderRepositoryMock.GetAsync(Arg.Any<int>()).Returns(Task.FromResult(order));
        _buyerRepositoryMock.FindByIdAsync(Arg.Any<int>()).Returns(Task.FromResult(buyer));
        _orderRepositoryMock.UnitOfWork.SaveEntitiesAsync(default).Returns(Task.FromResult(true));

        var handler = new RequestOrderReturnCommandHandler(_orderRepositoryMock, _buyerRepositoryMock);

        // Act
        var result = await handler.Handle(new RequestOrderReturnCommand(order.Id, "owner-identity", new Dictionary<int, int> { { 1, 2 } }), default);

        // Assert
        Assert.IsTrue(result);
        Assert.AreEqual(OrderStatus.ReturnRequested, order.OrderStatus);
        Assert.AreEqual(2, order.OrderItems.Single().ReturnedUnits);
    }

    [TestMethod]
    public async Task Handle_throws_when_return_quantity_exceeds_purchased_units()
    {
        // Arrange
        var order = PaidOrderWithOneItem(units: 5);
        var buyer = new Buyer("owner-identity", "Owner");

        _orderRepositoryMock.GetAsync(Arg.Any<int>()).Returns(Task.FromResult(order));
        _buyerRepositoryMock.FindByIdAsync(Arg.Any<int>()).Returns(Task.FromResult(buyer));

        var handler = new RequestOrderReturnCommandHandler(_orderRepositoryMock, _buyerRepositoryMock);

        // Act - Assert
        await Assert.ThrowsExceptionAsync<OrderingDomainException>(() =>
            handler.Handle(new RequestOrderReturnCommand(order.Id, "owner-identity", new Dictionary<int, int> { { 1, 6 } }), default));
    }

    [TestMethod]
    public async Task Handle_throws_when_order_is_not_in_a_returnable_status()
    {
        // Arrange - a freshly submitted order has not been paid or shipped yet
        var address = new Address("street", "city", "state", "country", "zipcode");
        var order = new Order("owner-identity", "Owner", address, 1, "card", "123", "Owner", DateTime.UtcNow.AddYears(1), buyerId: 1);
        order.AddOrderItem(1, "cup", 10.0m, 0, string.Empty, 5);
        var buyer = new Buyer("owner-identity", "Owner");

        _orderRepositoryMock.GetAsync(Arg.Any<int>()).Returns(Task.FromResult(order));
        _buyerRepositoryMock.FindByIdAsync(Arg.Any<int>()).Returns(Task.FromResult(buyer));

        var handler = new RequestOrderReturnCommandHandler(_orderRepositoryMock, _buyerRepositoryMock);

        // Act - Assert
        await Assert.ThrowsExceptionAsync<OrderingDomainException>(() =>
            handler.Handle(new RequestOrderReturnCommand(order.Id, "owner-identity", new Dictionary<int, int> { { 1, 1 } }), default));
    }

    private static Order PaidOrderWithOneItem(int units)
    {
        var address = new Address("street", "city", "state", "country", "zipcode");
        var order = new Order("owner-identity", "Owner", address, 1, "card", "123", "Owner", DateTime.UtcNow.AddYears(1), buyerId: 1);
        order.AddOrderItem(1, "cup", 10.0m, 0, string.Empty, units);
        order.SetAwaitingValidationStatus();
        order.SetStockConfirmedStatus();
        order.SetPaidStatus();
        return order;
    }
}
