namespace eShop.Ordering.API.Application.IntegrationEvents.EventHandling;

public class OrderRefundSucceededIntegrationEventHandler(
    IMediator mediator,
    ILogger<OrderRefundSucceededIntegrationEventHandler> logger) :
    IIntegrationEventHandler<OrderRefundSucceededIntegrationEvent>
{
    public async Task Handle(OrderRefundSucceededIntegrationEvent @event)
    {
        logger.LogInformation("Handling integration event: {IntegrationEventId} - ({@IntegrationEvent})", @event.Id, @event);

        var command = new SetRefundedOrderStatusCommand(@event.OrderId);

        logger.LogInformation(
            "Sending command: {CommandName} - {IdProperty}: {CommandId} ({@Command})",
            command.GetGenericTypeName(),
            nameof(command.OrderNumber),
            command.OrderNumber,
            command);

        await mediator.Send(command);
    }
}
