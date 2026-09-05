namespace eShop.Ordering.API.Application.IntegrationEvents.Events;

public record OrderPaymentRefundSucceededIntegrationEvent : IntegrationEvent
{
    public int OrderId { get; }

    public OrderPaymentRefundSucceededIntegrationEvent(int orderId) => OrderId = orderId;
}
