namespace eShop.PaymentProcessor.IntegrationEvents.Events;

public record OrderPaymentRefundSucceededIntegrationEvent(int OrderId) : IntegrationEvent;
