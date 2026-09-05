namespace eShop.PaymentProcessor.IntegrationEvents.Events;

public record OrderPaymentRefundFailedIntegrationEvent(int OrderId) : IntegrationEvent;
