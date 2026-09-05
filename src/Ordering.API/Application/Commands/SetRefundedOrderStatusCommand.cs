namespace eShop.Ordering.API.Application.Commands;

public record SetRefundedOrderStatusCommand(int OrderNumber) : IRequest<bool>;
