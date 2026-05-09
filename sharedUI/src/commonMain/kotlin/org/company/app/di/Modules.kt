package org.company.app.di

import org.company.app.feature.hello.data.HelloRepositoryImpl
import org.company.app.feature.hello.domain.GetHelloMessageUseCase
import org.company.app.feature.hello.domain.HelloRepository
import org.company.app.feature.hello.domain.RefreshHelloUseCase
import org.company.app.feature.hello.presentation.HelloViewModel
import org.koin.core.module.dsl.viewModelOf
import org.koin.dsl.module

/**
 * Cross-feature singletons (HttpClient, ApolloClient, Json, Settings, KStore, …).
 * Add a `single { ... }` here for any dependency that must be shared across features.
 */
val commonModule = module {
    // single { HttpClient(engine = get()) { … } }
    // single { ApolloClient.Builder().serverUrl(BuildConfig.GRAPHQL_URL).build() }
}

/**
 * Bindings for repository implementations. The presentation layer must NOT see these classes;
 * it only consumes the domain interfaces declared as `bind<...>()` here.
 */
val dataModule = module {
    single<HelloRepository> { HelloRepositoryImpl() }
}

/**
 * ViewModels and use cases. Use cases are factory-scoped to keep them stateless.
 */
val presentationModule = module {
    factory { GetHelloMessageUseCase(repository = get()) }
    factory { RefreshHelloUseCase(repository = get()) }
    viewModelOf(::HelloViewModel)
}

