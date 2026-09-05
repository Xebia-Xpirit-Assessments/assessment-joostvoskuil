namespace eShop.Ordering.API.Application.Commands;

// Regular CommandHandler
public class SetRefundedOrderStatusCommandHandler : IRequestHandler<SetRefundedOrderStatusCommand, bool>
{
    private readonly IOrderRepository _orderRepository;

    public SetRefundedOrderStatusCommandHandler(IOrderRepository orderRepository)
    {
        _orderRepository = orderRepository;
    }

    /// <summary>
    /// Handler which processes the command when
    /// the payment provider confirms the refund for a returned order.
    /// </summary>
    public async Task<bool> Handle(SetRefundedOrderStatusCommand command, CancellationToken cancellationToken)
    {
        var orderToUpdate = await _orderRepository.GetAsync(command.OrderNumber);
        if (orderToUpdate == null)
        {
            return false;
        }

        orderToUpdate.SetRefundedStatus();
        return await _orderRepository.UnitOfWork.SaveEntitiesAsync(cancellationToken);
    }
}
