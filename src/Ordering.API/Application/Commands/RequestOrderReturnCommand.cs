namespace eShop.Ordering.API.Application.Commands;

public record RequestOrderReturnCommand(int OrderNumber, string UserId, Dictionary<int, int> ItemsToReturn) : IRequest<bool>;
