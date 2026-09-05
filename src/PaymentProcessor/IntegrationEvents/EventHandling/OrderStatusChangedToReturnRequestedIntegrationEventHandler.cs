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
        // Here we're simulating that we'd be initiating a refund against the payment gateway
        // that was originally used to pay for the order.

        var orderRefundIntegrationEvent = new OrderRefundSucceededIntegrationEvent(@event.OrderId);

        logger.LogInformation("Publishing integration event: {IntegrationEventId} - ({@IntegrationEvent})", orderRefundIntegrationEvent.Id, orderRefundIntegrationEvent);

        await eventBus.PublishAsync(orderRefundIntegrationEvent);
    }
}
