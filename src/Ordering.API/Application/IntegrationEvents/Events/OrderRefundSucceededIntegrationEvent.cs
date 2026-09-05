namespace eShop.Ordering.API.Application.IntegrationEvents.Events;

public record OrderRefundSucceededIntegrationEvent : IntegrationEvent
{
    public int OrderId { get; }

    public OrderRefundSucceededIntegrationEvent(int orderId) => OrderId = orderId;
}
