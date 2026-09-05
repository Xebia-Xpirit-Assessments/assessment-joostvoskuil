namespace eShop.Ordering.API.Application.Validations;

public class RequestOrderReturnCommandValidator : AbstractValidator<RequestOrderReturnCommand>
{
    public RequestOrderReturnCommandValidator(ILogger<RequestOrderReturnCommandValidator> logger)
    {
        RuleFor(order => order.OrderNumber).NotEmpty().WithMessage("No orderId found");
        RuleFor(order => order.UserId).NotEmpty().WithMessage("No userId found");
        RuleFor(order => order.Items).NotEmpty().WithMessage("At least one item must be specified to request a return");

        if (logger.IsEnabled(LogLevel.Trace))
        {
            logger.LogTrace("INSTANCE CREATED - {ClassName}", GetType().Name);
        }
    }
}
