namespace eShop.Ordering.API.Application.IntegrationEvents.EventHandling;

public class OrderPaymentRefundFailedIntegrationEventHandler(
    ILogger<OrderPaymentRefundFailedIntegrationEventHandler> logger) :
    IIntegrationEventHandler<OrderPaymentRefundFailedIntegrationEvent>
{
    public Task Handle(OrderPaymentRefundFailedIntegrationEvent @event)
    {
        // Business feature comment:
        // The refund could not be processed by the payment provider. The order remains in the
        // ReturnRequested status so that customer support can follow up and retry or resolve manually.
        logger.LogWarning(
            "The refund for order {OrderId} could not be processed by the payment provider.",
            @event.OrderId);

        return Task.CompletedTask;
    }
}
