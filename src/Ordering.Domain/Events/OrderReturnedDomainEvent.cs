namespace eShop.Ordering.Domain.Events;

/// <summary>
/// Event used when a return/refund for an order has been completed by the payment provider.
/// </summary>
public class OrderReturnedDomainEvent : INotification
{
    public Order Order { get; }

    public OrderReturnedDomainEvent(Order order)
    {
        Order = order;
    }
}
