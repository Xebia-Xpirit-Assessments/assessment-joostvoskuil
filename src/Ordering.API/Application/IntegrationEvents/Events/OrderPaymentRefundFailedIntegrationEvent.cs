namespace eShop.Ordering.API.Application.IntegrationEvents.Events;

public record OrderPaymentRefundFailedIntegrationEvent : IntegrationEvent
{
    public int OrderId { get; }

    public OrderPaymentRefundFailedIntegrationEvent(int orderId) => OrderId = orderId;
}
