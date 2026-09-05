namespace eShop.Ordering.API.Application.Commands;

public record RequestOrderReturnCommand(int OrderNumber, string UserId, IDictionary<int, int> ReturnItems) : IRequest<bool>;
