namespace eShop.Ordering.API.Application.Commands;

public record SetOrderReturnedStatusCommand(int OrderNumber) : IRequest<bool>;
