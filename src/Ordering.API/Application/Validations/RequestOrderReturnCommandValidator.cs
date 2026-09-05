namespace eShop.Ordering.API.Application.Validations;

public class RequestOrderReturnCommandValidator : AbstractValidator<RequestOrderReturnCommand>
{
    public RequestOrderReturnCommandValidator(ILogger<RequestOrderReturnCommandValidator> logger)
    {
        RuleFor(order => order.OrderNumber).NotEmpty().WithMessage("No orderId found");
        RuleFor(order => order.UserId).NotEmpty().WithMessage("No user identity found");
        RuleFor(order => order.ReturnItems).NotEmpty().WithMessage("At least one item must be specified for return");

        if (logger.IsEnabled(LogLevel.Trace))
        {
            logger.LogTrace("INSTANCE CREATED - {ClassName}", GetType().Name);
        }
    }
}
