namespace eShop.Ordering.Domain.Events;

/// <summary>
/// Event used when a customer requests a full or partial return/refund for an order.
/// </summary>
public class OrderStatusChangedToReturnRequestedDomainEvent : INotification
{
    public Order Order { get; }

    public OrderStatusChangedToReturnRequestedDomainEvent(Order order)
    {
        Order = order;
    }
}
