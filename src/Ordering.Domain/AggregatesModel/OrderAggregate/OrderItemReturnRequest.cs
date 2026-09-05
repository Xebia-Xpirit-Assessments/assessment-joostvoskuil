namespace eShop.Ordering.Domain.AggregatesModel.OrderAggregate;

/// <summary>
/// Represents a request to return a given quantity of units of a product that
/// belongs to an order.
/// </summary>
public record OrderItemReturnRequest(int ProductId, int Units);
