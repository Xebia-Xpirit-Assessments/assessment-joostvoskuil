namespace eShop.Ordering.API.Application.IntegrationEvents.EventHandling;

public class OrderPaymentRefundSucceededIntegrationEventHandler(
    IMediator mediator,
    ILogger<OrderPaymentRefundSucceededIntegrationEventHandler> logger) :
    IIntegrationEventHandler<OrderPaymentRefundSucceededIntegrationEvent>
{
    public async Task Handle(OrderPaymentRefundSucceededIntegrationEvent @event)
    {
        logger.LogInformation("Handling integration event: {IntegrationEventId} - ({@IntegrationEvent})", @event.Id, @event);

        var command = new SetOrderReturnedStatusCommand(@event.OrderId);

        logger.LogInformation(
            "Sending command: {CommandName} - {IdProperty}: {CommandId} ({@Command})",
            command.GetGenericTypeName(),
            nameof(command.OrderNumber),
            command.OrderNumber,
            command);

        await mediator.Send(command);
    }
}
