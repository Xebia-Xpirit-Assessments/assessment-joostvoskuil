namespace eShop.Ordering.API.Application.Exceptions;

/// <summary>
/// Thrown when a customer attempts to act on an order that does not belong to them.
/// </summary>
public class OrderReturnNotAuthorizedException : Exception
{
    public OrderReturnNotAuthorizedException()
    { }

    public OrderReturnNotAuthorizedException(string message)
        : base(message)
    { }
}
