namespace eShop.Ordering.API.Application.Commands;

public record CompleteOrderReturnCommand(int OrderNumber) : IRequest<bool>;
