namespace eShop.Ordering.API.Application.Commands;

public record RequestOrderReturnCommand(int OrderNumber, string UserId, List<OrderItemReturnRequest> Items) : IRequest<bool>;
