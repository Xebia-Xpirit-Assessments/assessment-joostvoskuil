namespace eShop.PaymentProcessor.IntegrationEvents.EventHandling;

public class OrderStatusChangedToReturnRequestedIntegrationEventHandler(
    IEventBus eventBus,
    ILogger<OrderStatusChangedToReturnRequestedIntegrationEventHandler> logger) :
    IIntegrationEventHandler<OrderStatusChangedToReturnRequestedIntegrationEvent>
{
    public async Task Handle(OrderStatusChangedToReturnRequestedIntegrationEvent @event)
    {
        logger.LogInformation("Handling integration event: {IntegrationEventId} - ({@IntegrationEvent})", @event.Id, @event);

        // Business feature comment:
        // When OrderStatusChangedToReturnRequested Integration Event is handled.
        // Here we're simulating that we'd be performing the refund against any payment gateway
        // on behalf of the customer's self-service return.
        var orderRefundSucceededIntegrationEvent = new OrderRefundSucceededIntegrationEvent(@event.OrderId);

        logger.LogInformation("Publishing integration event: {IntegrationEventId} - ({@IntegrationEvent})", orderRefundSucceededIntegrationEvent.Id, orderRefundSucceededIntegrationEvent);

        await eventBus.PublishAsync(orderRefundSucceededIntegrationEvent);
    }
}
