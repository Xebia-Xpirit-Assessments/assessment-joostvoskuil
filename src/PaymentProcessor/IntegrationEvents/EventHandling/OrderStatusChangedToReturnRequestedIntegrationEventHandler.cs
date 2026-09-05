namespace eShop.PaymentProcessor.IntegrationEvents.EventHandling;

public class OrderStatusChangedToReturnRequestedIntegrationEventHandler(
    IEventBus eventBus,
    IOptionsMonitor<PaymentOptions> options,
    ILogger<OrderStatusChangedToReturnRequestedIntegrationEventHandler> logger) :
    IIntegrationEventHandler<OrderStatusChangedToReturnRequestedIntegrationEvent>
{
    public async Task Handle(OrderStatusChangedToReturnRequestedIntegrationEvent @event)
    {
        logger.LogInformation("Handling integration event: {IntegrationEventId} - ({@IntegrationEvent})", @event.Id, @event);

        IntegrationEvent orderPaymentRefundIntegrationEvent;

        // Business feature comment:
        // When OrderStatusChangedToReturnRequested Integration Event is handled.
        // Here we're simulating that we'd be performing the refund against any payment gateway
        // Instead of a real refund we just take the env. var to simulate the payment provider outcome
        // The refund can be successful or it can fail

        if (options.CurrentValue.PaymentSucceeded)
        {
            orderPaymentRefundIntegrationEvent = new OrderPaymentRefundSucceededIntegrationEvent(@event.OrderId);
        }
        else
        {
            orderPaymentRefundIntegrationEvent = new OrderPaymentRefundFailedIntegrationEvent(@event.OrderId);
        }

        logger.LogInformation("Publishing integration event: {IntegrationEventId} - ({@IntegrationEvent})", orderPaymentRefundIntegrationEvent.Id, orderPaymentRefundIntegrationEvent);

        await eventBus.PublishAsync(orderPaymentRefundIntegrationEvent);
    }
}
