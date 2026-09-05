namespace eShop.PaymentProcessor.IntegrationEvents.Events;

public record OrderRefundSucceededIntegrationEvent(int OrderId) : IntegrationEvent;
