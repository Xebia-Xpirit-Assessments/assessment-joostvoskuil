namespace eShop.Ordering.Domain.Events;

/// <summary>
/// Event used when an order return has been refunded
/// </summary>
public class OrderRefundedDomainEvent
    : INotification
{
    public Order Order { get; }

    public OrderRefundedDomainEvent(Order order)
    {
        Order = order;
    }
}
