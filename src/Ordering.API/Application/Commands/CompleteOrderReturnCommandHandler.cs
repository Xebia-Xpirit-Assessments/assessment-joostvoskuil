namespace eShop.Ordering.API.Application.Commands;

// Regular CommandHandler
public class CompleteOrderReturnCommandHandler : IRequestHandler<CompleteOrderReturnCommand, bool>
{
    private readonly IOrderRepository _orderRepository;

    public CompleteOrderReturnCommandHandler(IOrderRepository orderRepository)
    {
        _orderRepository = orderRepository;
    }

    /// <summary>
    /// Handler which processes the command when
    /// the payment provider confirms the refund for a requested return
    /// </summary>
    /// <param name="command"></param>
    /// <returns></returns>
    public async Task<bool> Handle(CompleteOrderReturnCommand command, CancellationToken cancellationToken)
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
