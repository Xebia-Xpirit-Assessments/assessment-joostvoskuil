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
    /// Handler which processes the command when a customer
    /// requests a full or partial return for their own order.
    /// </summary>
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

        if (buyer is null || buyer.IdentityGuid != command.UserId)
        {
            throw new OrderingDomainException("You are not authorized to request a return for this order.");
        }

        orderToUpdate.RequestReturn(command.ItemsToReturn);
        return await _orderRepository.UnitOfWork.SaveEntitiesAsync(cancellationToken);
    }
}


// Use for Idempotency in Command process
public class RequestOrderReturnIdentifiedCommandHandler : IdentifiedCommandHandler<RequestOrderReturnCommand, bool>
{
    public RequestOrderReturnIdentifiedCommandHandler(
        IMediator mediator,
        IRequestManager requestManager,
        ILogger<IdentifiedCommandHandler<RequestOrderReturnCommand, bool>> logger)
        : base(mediator, requestManager, logger)
    {
    }

    protected override bool CreateResultForDuplicateRequest()
    {
        return true; // Ignore duplicate requests for processing the return request.
    }
}
