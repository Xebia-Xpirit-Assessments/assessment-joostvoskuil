namespace eShop.Ordering.API.Application.Commands;

// Regular CommandHandler
public class SetOrderReturnedStatusCommandHandler : IRequestHandler<SetOrderReturnedStatusCommand, bool>
{
    private readonly IOrderRepository _orderRepository;

    public SetOrderReturnedStatusCommandHandler(IOrderRepository orderRepository)
    {
        _orderRepository = orderRepository;
    }

    /// <summary>
    /// Handler which processes the command when
    /// the payment provider confirms the refund for a returned order
    /// </summary>
    /// <param name="command"></param>
    /// <returns></returns>
    public async Task<bool> Handle(SetOrderReturnedStatusCommand command, CancellationToken cancellationToken)
    {
        var orderToUpdate = await _orderRepository.GetAsync(command.OrderNumber);
        if (orderToUpdate == null)
        {
            return false;
        }

        orderToUpdate.SetReturnedStatus();
        return await _orderRepository.UnitOfWork.SaveEntitiesAsync(cancellationToken);
    }
}
