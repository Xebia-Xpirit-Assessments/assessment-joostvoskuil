namespace eShop.Ordering.Domain.Events;

/// <summary>
/// Event used when a customer requests a full or partial return for an order
/// </summary>
public class OrderReturnRequestedDomainEvent
    : INotification
{
    public Order Order { get; }

    public OrderReturnRequestedDomainEvent(Order order)
    {
        Order = order;
    }
}
