namespace eShop.Ordering.Domain.Events;

public class OrderStatusChangedToRefundedDomainEvent : INotification
{
    public Order Order { get; }

    public OrderStatusChangedToRefundedDomainEvent(Order order)
    {
        Order = order;
    }
}
