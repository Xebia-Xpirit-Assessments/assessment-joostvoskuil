using eShop.Ordering.Domain.AggregatesModel.BuyerAggregate;
using eShop.Ordering.Domain.AggregatesModel.OrderAggregate;

namespace eShop.Ordering.UnitTests.Application;

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
        //Arrange
        _orderRepositoryMock.GetAsync(Arg.Any<int>()).Returns((Order)null);
        var handler = new RequestOrderReturnCommandHandler(_orderRepositoryMock, _buyerRepositoryMock);
        var command = new RequestOrderReturnCommand(1, "buyer-identity", new Dictionary<int, int> { [1] = 1 });

        //Act
        var result = await handler.Handle(command, default);

        //Assert
        Assert.IsFalse(result);
    }

    [TestMethod]
    public async Task Handle_throws_when_requesting_user_does_not_own_the_order()
    {
        //Arrange
        var order = FakeOrderWithPaidItem(buyerId: 42);
        _orderRepositoryMock.GetAsync(Arg.Any<int>()).Returns(order);
        _buyerRepositoryMock.FindByIdAsync(42).Returns(new Buyer("owner-identity", "Owner"));

        var handler = new RequestOrderReturnCommandHandler(_orderRepositoryMock, _buyerRepositoryMock);
        var command = new RequestOrderReturnCommand(order.Id, "someone-else-identity", new Dictionary<int, int> { [1] = 1 });

        //Act - Assert
        await Assert.ThrowsExceptionAsync<OrderingDomainException>(() => handler.Handle(command, default));
    }

    [TestMethod]
    public async Task Handle_succeeds_for_partial_return_by_owner()
    {
        //Arrange
        var order = FakeOrderWithPaidItem(buyerId: 42);
        _orderRepositoryMock.GetAsync(Arg.Any<int>()).Returns(order);
        _buyerRepositoryMock.FindByIdAsync(42).Returns(new Buyer("owner-identity", "Owner"));
        _orderRepositoryMock.UnitOfWork.SaveEntitiesAsync(default).ReturnsForAnyArgs(Task.FromResult(true));

        var handler = new RequestOrderReturnCommandHandler(_orderRepositoryMock, _buyerRepositoryMock);
        var command = new RequestOrderReturnCommand(order.Id, "owner-identity", new Dictionary<int, int> { [1] = 1 });

        //Act
        var result = await handler.Handle(command, default);

        //Assert
        Assert.IsTrue(result);
        Assert.AreEqual(OrderStatus.ReturnRequested, order.OrderStatus);
    }

    private static Order FakeOrderWithPaidItem(int buyerId)
    {
        var order = new Order(
            "userId",
            "fakeName",
            new Address("street", "city", "state", "country", "zipcode"),
            cardTypeId: 5,
            cardNumber: "12",
            cardSecurityNumber: "123",
            cardHolderName: "name",
            cardExpiration: DateTime.UtcNow.AddYears(1),
            buyerId: buyerId);

        order.AddOrderItem(1, "cup", 10.0m, 0, string.Empty, units: 3);
        order.SetAwaitingValidationStatus();
        order.SetStockConfirmedStatus();
        order.SetPaidStatus();

        return order;
    }
}
