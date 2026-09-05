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
    /// Handler which processes the command when
    /// a customer requests a return for their own order
    /// </summary>
    /// <param name="command"></param>
    /// <returns></returns>
    public async Task<bool> Handle(RequestOrderReturnCommand command, CancellationToken cancellationToken)
    {
        var orderToUpdate = await _orderRepository.GetAsync(command.OrderNumber);
        if (orderToUpdate == null)
        {
            return false;
        }

        var buyer = orderToUpdate.BuyerId.HasValue
            ? await _buyerRepository.FindByIdAsync(orderToUpdate.BuyerId.Value)
            : null;

        if (buyer == null || string.IsNullOrEmpty(command.UserId) || buyer.IdentityGuid != command.UserId)
        {
            throw new OrderingDomainException("You are not authorized to request a return for this order.");
        }

        orderToUpdate.RequestReturn(command.ReturnItems);
        return await _orderRepository.UnitOfWork.SaveEntitiesAsync(cancellationToken);
    }
}
