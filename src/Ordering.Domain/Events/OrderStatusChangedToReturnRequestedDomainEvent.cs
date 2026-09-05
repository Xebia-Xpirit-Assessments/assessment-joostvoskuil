namespace eShop.Ordering.Domain.Events;

public class OrderStatusChangedToReturnRequestedDomainEvent : INotification
{
    public Order Order { get; }

    public OrderStatusChangedToReturnRequestedDomainEvent(Order order)
    {
        Order = order;
    }
}
