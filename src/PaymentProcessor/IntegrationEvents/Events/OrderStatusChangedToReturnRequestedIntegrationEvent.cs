namespace eShop.PaymentProcessor.IntegrationEvents.Events;

public record OrderStatusChangedToReturnRequestedIntegrationEvent(int OrderId) : IntegrationEvent;
