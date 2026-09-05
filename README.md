# eShop – GitHub Enterprise Blueprint
> This assignment is part of the Xebia GitHub Architect hiring process. You should have received companion documents that explain the details of the procedure and an overview of the company eShop.

![eShop Logo](https://github.com/user-attachments/assets/52ef76f4-54c8-4bb8-8c50-f5383925fa1a)

## The Assignment
eShop is looking for a partner who can help design and set up a GitHub Enterprise environment that lets them scale safely. As Xebia, we are asked to help design that setup and deliver a Proof of Concept: a single repository, configured the way every future eShop repository should be.

### Backstory
eShop started a few years ago as a small e-commerce venture, built out of the founders' personal GitHub accounts. The codebase grew quickly, and so did the number of repositories and developers working on it — all still under personal accounts, with no shared standards.

That growth attracted the interest of an investor willing to fund eShop's transformation into an enterprise-grade company. During due diligence, however, a supply chain attack was traced back to a compromised dependency in one of eShop's personal repositories. The investment is now on hold until eShop's board can see a credible plan — and a working example — of how engineering will be governed going forward.

eShop has one month to bring that plan to its board.

### Your task
Configure this repository so it can serve as the **blueprint** for eShop's future repositories: a reference that shows other teams, and the board, what "good" looks like once eShop is running on GitHub Enterprise.

## Topics to think about
We're deliberately not handing you a checklist of acceptance criteria here — part of this assessment is judging for yourself what a well-run repository needs. Below are the areas the board cares about; how far you take each one, and what you prioritize in the time you have, is up to you.

- **Repository structure & governance** — how is the repository organized, and what rules decide who can change what?
- **Security guardrails** — what would have caught, or at least slowed down, the kind of supply chain issue eShop just went through?
- **CI/CD** — eShop deploys .NET applications to Azure; what does a trustworthy pipeline look like?
- **Compliance** — the board wants to move towards ISO 27001. What does that mean at the level of a single repository?
- **Onboarding & documentation** — eShop's 3 development teams will need to adopt this way of working. What do they need to get started?
- **AI enablement** — eShop wants a vision on this. Where would it fit into a repository like this one, and where wouldn't it?
- **Surprise us** — is there something else you'd want a GitHub Enterprise blueprint to have that isn't listed above? 😊

## Checklist
Implement the parts of this blueprint that best demonstrate your approach. We are more interested in how you think about structure, security and governance than in covering every topic above completely.

Also think about how a repository like this fits into the bigger picture: an organization with multiple teams, a board that needs to be convinced, and a one-month deadline.

> Be realistic with the limited amount of time. This is a starting point for the technical discussion about architecture, security and development practices — not a finished product.

‼️ As stated before, do reach out if and when you have any questions. Don't assume. Ask!