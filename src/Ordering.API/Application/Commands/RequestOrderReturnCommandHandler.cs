namespace eShop.Ordering.API.Application.Commands;

// Regular CommandHandler
public class RequestOrderReturnCommandHandler : IRequestHandler<RequestOrderReturnCommand, bool>
{
    private readonly IOrderRepository _orderRepository;
    private readonly IBuyerRepository _buyerRepository;

    public RequestOrderReturnCommandHandler(IOrderRepository orderRepository, IBuyerRepository buyerRepository)
    {
        _orderRepository = orderRepository;
        _buyerRepository = buyerRepository;
    }

    /// <summary>
    /// Handler which processes the command when a customer requests a full or
    /// partial return/refund for one of their own orders.
    /// </summary>
    /// <param name="command"></param>
    /// <returns></returns>
    public async Task<bool> Handle(RequestOrderReturnCommand command, CancellationToken cancellationToken)
    {
        var orderToUpdate = await _orderRepository.GetAsync(command.OrderNumber);
        if (orderToUpdate == null)
        {
            throw new KeyNotFoundException($"Order {command.OrderNumber} was not found.");
        }

        var buyer = orderToUpdate.BuyerId.HasValue
            ? await _buyerRepository.FindByIdAsync(orderToUpdate.BuyerId.Value)
            : null;

        if (buyer is null || !string.Equals(buyer.IdentityGuid, command.UserId, StringComparison.Ordinal))
        {
            throw new OrderReturnNotAuthorizedException(
                $"User {command.UserId} is not authorized to request a return for order {command.OrderNumber}.");
        }

        orderToUpdate.RequestReturn(command.Items);
        return await _orderRepository.UnitOfWork.SaveEntitiesAsync(cancellationToken);
    }
}
